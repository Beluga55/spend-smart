import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;

class NvidiaAIService {
  final String apiKey;
  static const String _baseUrl = 'https://integrate.api.nvidia.com/v1';
  static const String _model = 'minimaxai/minimax-m2.7';

  NvidiaAIService(this.apiKey);

  bool get isConfigured => apiKey.isNotEmpty && apiKey != 'nvapi-YOUR_KEY_HERE';

  Future<String> _chat(String text, {double temp = 0.2, int tokens = 512}) async {
    if (!isConfigured) {
      throw Exception('API key not configured. Add NVIDIA_API_KEY to .env');
    }

    final body = jsonEncode({
      'model': _model,
      'messages': [
        {'role': 'system', 'content': 'You are a helpful assistant.'},
        {'role': 'user', 'content': text},
      ],
      'temperature': temp,
      'max_tokens': tokens,
    });

    developer.log('[NVIDIA] Request model: $_model');

    final res = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    ).timeout(const Duration(seconds: 15), onTimeout: () {
      throw Exception('NVIDIA request timed out after 15s');
    });

    developer.log('[NVIDIA] Response ${res.statusCode}: ${res.body.substring(0, res.body.length.clamp(0, 500))}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['choices']?[0]?['message']?['content'] as String? ?? '';
    }
    throw HttpException('NVIDIA API ${res.statusCode}: ${res.body}');
  }

  /// Robustly extract JSON from a model response that may wrap it in markdown.
  static Map<String, dynamic> _extractJson(String raw) {
    // 1. Strip markdown code blocks
    var text = raw;
    final codeBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = codeBlock.firstMatch(text);
    if (match != null) {
      text = match.group(1)!;
    }

    // 2. Find first balanced { ... } or [ ... ]
    final objectMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').firstMatch(text);
    final arrayMatch = RegExp(r'\[[^\[\]]*(?:\[[^\[\]]*\][^\[\]]*)*\]').firstMatch(text);

    String? jsonStr;
    if (objectMatch != null) {
      jsonStr = objectMatch.group(0);
    } else if (arrayMatch != null) {
      jsonStr = arrayMatch.group(0);
    }

    if (jsonStr != null) {
      try {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (_) {}
    }

    // 3. Fallback — simple string search for key: value patterns
    final result = <String, dynamic>{};
    String? grab(String key) {
      final idx = text.toLowerCase().indexOf(key.toLowerCase());
      if (idx == -1) return null;
      final after = text.substring(idx + key.length);
      final colon = after.indexOf(':');
      if (colon == -1) return null;
      var val = after.substring(colon + 1);
      val = val.split(RegExp(r'[,}\n]')).first.trim();
      val = val.replaceAll("'", '').replaceAll('"', '');
      return val.isEmpty ? null : val;
    }

    result['merchant'] = grab('merchant');
    result['date'] = grab('date');
    result['currency'] = grab('currency');
    final totalStr = grab('total');
    result['total'] = totalStr != null ? double.tryParse(totalStr) : null;

    // 4. If even that failed, return raw for debugging
    if (result.values.every((v) => v == null)) {
      return {'raw': raw};
    }
    return result;
  }

  Future<Map<String, dynamic>> parseReceipt(String ocrText) async {
    final prompt =
        'You are a receipt parser. Extract these exact fields from the OCR text and return ONLY a JSON object with no markdown, no code blocks, no explanation.\n\n'
        'Required JSON keys:\n'
        '- "merchant": store or seller name (string, best guess if unclear)\n'
        '- "date": ISO date YYYY-MM-DD (guess from any date format found; use today if none)\n'
        '- "total": final paid amount as a number (look for "Total", "Grand Total", "Amount Due", "Balance", the largest number near the bottom)\n'
        '- "currency": 3-letter ISO code (USD, EUR, GBP, CNY, JPY, MYR, SGD, etc.). Guess from currency symbols or location context. Use null if unknown.\n'
        '- "items": optional array of line items, each with "description" (string) and "amount" (number). Only include if clearly visible.\n\n'
        'Rules:\n'
        '1. Return ONLY raw JSON. No ```json wrappers. No extra text.\n'
        '2. If a field is missing, use null (not "N/A" or "unknown").\n'
        '3. For "total", prefer the final/grand total over subtotals. Remove currency symbols.\n'
        '4. For "date", convert any format (MM/DD/YYYY, DD-MM-YYYY, "Jan 5 2024", etc.) to YYYY-MM-DD.\n'
        '5. For "merchant", look at the top of the receipt. If multiple names exist, pick the store name (not the payment processor).\n\n'
        'Example response for a unclear receipt:\n'
        '{"merchant":"7-Eleven","date":"2024-05-09","total":12.50,"currency":"USD","items":[{"description":"Coffee","amount":3.50},{"description":"Sandwich","amount":6.00}]}\n\n'
        'OCR text:\n$ocrText';

    final raw = await _chat(prompt, temp: 0.05, tokens: 512);
    return _extractJson(raw);
  }

  Future<String> suggestCategory(String label, List<String> cats) async {
    final prompt =
        'You are a personal finance categorizer. Pick the single best category for this expense.\n\n'
        'Rules:\n'
        '1. Reply with ONLY the exact category name from the list below.\n'
        '2. No quotes, no numbers, no explanation, no extra text.\n'
        '3. If unsure, pick the closest match.\n\n'
        'Expense label: "$label"\n\n'
        'Available categories:\n${cats.map((c) => '- $c').join('\n')}';
    return (await _chat(prompt, temp: 0.05, tokens: 64)).trim();
  }

  Future<String> generateMonthlyInsights({
    required double spent,
    required double income,
    required double budget,
    required List<Map<String, dynamic>> topCats,
    required int txns,
  }) async {
    final cats = topCats.map((c) => '${c['name']}: \$${c['amount']}').join('\n');
    final prompt =
        'You are a personal finance assistant. Give exactly 1 concise, actionable insight '
        'about this monthly spending (1-2 sentences max). Be specific and helpful.\n\n'
        'Spent: \$$spent | Income: \$$income | Budget: \$$budget | Transactions: $txns\n'
        'Top categories:\n$cats';
    return _chat(prompt, temp: 0.3, tokens: 256);
  }

  Future<String?> answerSpendingQuery(
    String query,
    List<Map<String, dynamic>> txns,
  ) async {
    final list = txns
        .map((t) => '${t['date']} | ${t['category']} | \$${t['amount']}')
        .join('\n');
    final prompt =
        'Answer this question using only the provided transaction data. Be concise.\n\n'
        'Transactions:\n$list\n\nQuestion: $query';
    return (await _chat(prompt, temp: 0.2, tokens: 256)).trim();
  }

  /// Agent-style chat that can answer questions OR perform actions.
  /// Returns a JSON map with keys: type, message, action (optional).
  Future<Map<String, dynamic>> chat({
    required String query,
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> history,
  }) async {
    final prompt = _buildChatPrompt(query, context, history);
    final raw = await _chat(prompt, temp: 0.2, tokens: 1024);
    return _extractChatResponse(raw);
  }

  String _buildChatPrompt(
    String query,
    Map<String, dynamic> context,
    List<Map<String, dynamic>> history,
  ) {
    final categories = (context['categories'] as List<dynamic>? ?? [])
        .map((c) => '- ${c['name']} (${c['type']})')
        .join('\n');

    final expenses = (context['expenses'] as List<dynamic>? ?? [])
        .take(30)
        .map((e) => '${e['date']} | ${e['category']} | \$${e['amount']} | ${e['note'] ?? ''}')
        .join('\n');

    final incomes = (context['incomes'] as List<dynamic>? ?? [])
        .take(20)
        .map((i) => '${i['date']} | ${i['source']} | \$${i['amount']} | ${i['note'] ?? ''}')
        .join('\n');

    final budgets = (context['budgets'] as List<dynamic>? ?? [])
        .map((b) => '${b['name']}: \$${b['limit']}')
        .join('\n');

    final wallets = (context['wallets'] as List<dynamic>? ?? [])
        .map((w) => '${w['name']}: \$${w['balance']}')
        .join('\n');

    final historyText = history.isEmpty
        ? 'None'
        : history
            .map((h) => '${h['role']}: ${h['content']}')
            .join('\n');

    return
        'You are SpendSmart AI, a personal finance assistant inside a mobile expense tracker app. '
        'You can answer questions about the user\'s finances AND perform actions like creating expenses, incomes, or categories.\n\n'
        '=== AVAILABLE DATA ===\n'
        'Total Balance: \$${context['totalBalance'] ?? 0}\n'
        'Monthly Expense Total: \$${context['monthlyExpenseTotal'] ?? 0}\n'
        'Monthly Income Total: \$${context['monthlyIncomeTotal'] ?? 0}\n'
        'Monthly Balance: \$${context['monthlyBalance'] ?? 0}\n\n'
        'Categories:\n$categories\n\n'
        'Recent Expenses (last 30):\n${expenses.isEmpty ? "None" : expenses}\n\n'
        'Recent Incomes (last 20):\n${incomes.isEmpty ? "None" : incomes}\n\n'
        'Budgets:\n${budgets.isEmpty ? "None" : budgets}\n\n'
        'Wallets:\n${wallets.isEmpty ? "None" : wallets}\n\n'
        '=== CONVERSATION HISTORY ===\n'
        '$historyText\n\n'
        '=== INSTRUCTIONS ===\n'
        'Analyze the user message and classify the intent. '
        'Respond with ONLY a JSON object (no markdown, no explanation, no ``` wrappers).\n\n'
        'JSON format:\n'
        '{\n'
        '  "type": "answer" | "create_expense" | "create_income" | "create_category" | "delete_expense" | "delete_income" | "delete_category",\n'
        '  "message": "friendly text reply to show the user",\n'
        '  "action": { ... } // only for non-answer types\n'
        '}\n\n'
        'For "create_expense" action:\n'
        '{\n'
        '  "amount": number (required),\n'
        '  "category": "exact category name from available categories (required)",\n'
        '  "date": "YYYY-MM-DD" (use today if not specified),\n'
        '  "note": "string or null"\n'
        '}\n\n'
        'For "create_income" action:\n'
        '{\n'
        '  "amount": number (required),\n'
        '  "source": "exact source name from available income categories or a new one (required)",\n'
        '  "date": "YYYY-MM-DD" (use today if not specified),\n'
        '  "note": "string or null"\n'
        '}\n\n'
        'For "create_category" action:\n'
        '{\n'
        '  "name": "category name (required)",\n'
        '  "iconName": "Material icon name like "restaurant" or "shopping_cart" (required)",\n'
        '  "color": "hex color string like #FF5733 (required)",\n'
        '  "categoryType": "expense" or "income" (required)\n'
        '}\n\n'
        'For "delete_expense" action:\n'
        '{\n'
        '  "amount": number (optional, helps find the right one),\n'
        '  "category": "exact category name (optional)",\n'
        '  "date": "YYYY-MM-DD" (optional),\n'
        '  "note": "string or null" (optional, used for matching)\n'
        '}\n\n'
        'For "delete_income" action:\n'
        '{\n'
        '  "amount": number (optional),\n'
        '  "source": "exact source name (optional)",\n'
        '  "date": "YYYY-MM-DD" (optional),\n'
        '  "note": "string or null" (optional)\n'
        '}\n\n'
        'For "delete_category" action:\n'
        '{\n'
        '  "name": "category name (required)"\n'
        '}\n\n'
        'Rules:\n'
        '1. If creating an expense/income and the category/source does not exist, prefer to use create_category first in a separate message, or pick the closest existing match.\n'
        '2. Use today\'s date (${DateTime.now().toIso8601String().split('T').first}) if the user does not specify a date.\n'
        '3. Return ONLY raw JSON. No markdown code blocks. No extra text outside the JSON.\n'
        '4. Keep the message concise, friendly, and actionable.\n'
        '5. For answer type, the action field can be omitted or null.\n'
        '6. For delete actions, be as specific as possible (amount + date + note) to avoid deleting the wrong item.\n'
        '7. You cannot delete default categories or categories that have transactions.\n\n'
        'User message: $query';
  }

  static Map<String, dynamic> _extractChatResponse(String raw) {
    // 1. Strip markdown code blocks
    var text = raw;
    final codeBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = codeBlock.firstMatch(text);
    if (match != null) {
      text = match.group(1)!;
    }

    // 2. Find first balanced { ... }
    final objectMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').firstMatch(text);
    if (objectMatch != null) {
      final jsonStr = objectMatch.group(0);
      try {
        final parsed = jsonDecode(jsonStr!) as Map<String, dynamic>;
        if (parsed.containsKey('type') && parsed.containsKey('message')) {
          return parsed;
        }
      } catch (_) {}
    }

    // 3. Fallback — treat the whole thing as an answer
    return {
      'type': 'answer',
      'message': raw.trim(),
    };
  }
}
