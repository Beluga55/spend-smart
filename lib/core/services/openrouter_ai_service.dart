import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;

/// OpenRouter AI service implementation using raw HTTP calls.
///
/// Provides access to OpenRouter's API with the openrouter/free model.
/// Implements the same interface as GeminiAIService and NvidiaAIService.
class OpenRouterAIService {
  final String apiKey;
  final String model;

  OpenRouterAIService(this.apiKey, {this.model = 'openrouter/free'});

  bool get isConfigured => apiKey.isNotEmpty;

  static const String _baseUrl = 'https://openrouter.ai/api/v1';

  Future<Map<String, String>> _getHeaders() async {
    return {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://github.com/mobile-expense-tracker',
      'X-Title': 'SpendSmart Expense Tracker',
    };
  }

  Future<String> _generate(
    String prompt, {
    double temp = 0.2,
    int tokens = 1024,
  }) async {
    debugPrint(
      '[OpenRouter] _generate called, API key present: ${apiKey.isNotEmpty}',
    );
    if (apiKey.isEmpty) {
      debugPrint('[OpenRouter] ERROR: API key is empty');
      throw Exception('OpenRouter API key is not configured');
    }
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: headers,
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful financial assistant.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': temp,
        'max_tokens': tokens,
      }),
    );

    debugPrint('[OpenRouter] Response status: ${response.statusCode}');
    debugPrint('[OpenRouter] Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'OpenRouter API error: ${response.statusCode} - ${response.body}',
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('[OpenRouter] Parsed response: ${data.keys.toList()}');

      if (data['choices'] == null) {
        throw Exception('No choices field in response');
      }
      if (data['choices'].isEmpty) {
        throw Exception('Choices array is empty');
      }
      if (data['choices'][0]['message'] == null) {
        throw Exception('No message field in first choice');
      }
      if (data['choices'][0]['message']['content'] == null) {
        throw Exception('No content field in message');
      }

      final content = data['choices'][0]['message']['content'] as String;

      debugPrint(
        '[OpenRouter] Success: ${content.length > 100 ? content.substring(0, 100) : content}...',
      );
      return content;
    } catch (e) {
      debugPrint('[OpenRouter] JSON parsing error: $e');
      debugPrint('[OpenRouter] Response body was: ${response.body}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> parseReceipt(String ocrText) async {
    final prompt =
        '''Extract information from this OCR text and return JSON:

OCR Text:
$ocrText

Return JSON with:
{
  "merchant": "store name",
  "date": "YYYY-MM-DD",
  "total": number,
  "currency": "3-letter code",
  "items": [
    {"name": "item", "price": number}
  ]
}

If unsure, set field to null. Return ONLY raw JSON.''';

    final raw = await _generate(prompt, temp: 0.1, tokens: 512);
    return _extractJson(raw);
  }

  Future<String> suggestCategory(String label, List<String> categories) async {
    final prompt =
        '''Pick the best category for: "$label"

Available categories:
${categories.map((c) => '- $c').join('\n')}

Return only the exact category name. No explanation.''';

    return await _generate(prompt, temp: 0.2, tokens: 50);
  }

  Future<String> generateMonthlyInsights({
    required double spent,
    required double income,
    required double budget,
    required List<Map<String, dynamic>> topCats,
    required int txns,
  }) async {
    final prompt =
        '''Generate concise monthly insights (2-3 sentences):

- Spent: $spent
- Income: $income
- Budget: $budget
- Top categories: ${topCats.map((c) => '${c['name']}: ${c['amount']}').join(', ')}
- Transactions: $txns

Focus on spending patterns and budget status. Be encouraging but honest.''';

    return await _generate(prompt, temp: 0.7, tokens: 150);
  }

  Future<String?> answerSpendingQuery(
    String query,
    List<Map<String, dynamic>> txns,
  ) async {
    final prompt =
        '''Answer this question about transactions:

Question: $query

Transactions:
${txns.map((t) => '${t['date']}: ${t['note']} - \$${t['amount']} (${t['category']})').join('\n')}

Be concise and specific. Use exact amounts and dates.''';

    return await _generate(prompt, temp: 0.3, tokens: 200);
  }

  Future<Map<String, dynamic>> chat({
    required String query,
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> history,
  }) async {
    final prompt = _buildChatPrompt(query, context, history);
    final raw = await _generate(prompt, temp: 0.2, tokens: 1024);
    return _extractChatResponse(raw);
  }

  String _buildChatPrompt(
    String query,
    Map<String, dynamic> context,
    List<Map<String, dynamic>> history,
  ) {
    final historyText = history
        .map((msg) => '${msg['role']}: ${msg['content']}')
        .join('\n');

    return '''You are a helpful financial assistant for SpendSmart. You can answer questions AND perform actions.

Current context:
- Total balance: \$${context['balance'] ?? 0}
- This month spent: \$${context['monthSpent'] ?? 0}
- This month income: \$${context['monthIncome'] ?? 0}
- Categories: ${(context['categories'] as List?)?.map((c) => c['name']).join(', ') ?? ''}
- Wallets: ${(context['wallets'] as List?)?.map((w) => '${w['name']} (\$${w['balance']})${w['isDefault'] == true ? ' [default]' : ''}').join(', ') ?? ''}
- Recent expenses: ${(context['recentExpenses'] as List?)?.map((e) => '${e['note']} - \$${e['amount']}').join(', ') ?? ''}
- Recent incomes: ${(context['recentIncomes'] as List?)?.map((i) => '${i['source']} - \$${i['amount']}').join(', ') ?? ''}

Recent chat history:
$historyText

When responding, return JSON with:
{
  "type": "answer|create_expense|create_income|create_category|delete_expense|delete_income|delete_category|create_multiple_expenses|create_multiple_incomes|create_transfer",
  "message": "Your response to the user",
  "action": { ... } // optional, depends on type
}

For "create_expense" action:
{
  "amount": number (required),
  "category": "exact category name (required)",
  "wallet": "exact wallet name (optional, use the default wallet if user does not specify)",
  "date": "YYYY-MM-DD" (optional),
  "note": "string or null" (optional)
}

For "create_income" action:
{
  "amount": number (required),
  "source": "exact source name (required)",
  "wallet": "exact wallet name (optional, use the default wallet if user does not specify)",
  "date": "YYYY-MM-DD" (optional),
  "note": "string or null" (optional)
}

For "create_category" action:
{
  "name": "category name (required)",
  "iconName": "icon name (optional)",
  "color": "hex color (optional)",
  "categoryType": "expense|income (optional)"
}

For "create_transfer" action (use when user wants to transfer money between wallets):
{
  "amount": number (required),
  "fromWallet": "exact source wallet name (required)",
  "toWallet": "exact destination wallet name (required)",
  "date": "YYYY-MM-DD" (optional),
  "note": "string or null" (optional)
}

For "delete_expense" action:
{
  "amount": number (required),
  "category": "category name (required)",
  "date": "YYYY-MM-DD" (required),
  "note": "note or null (required)"
}

For "delete_income" action:
{
  "amount": number (required),
  "source": "source name (required),
  "date": "YYYY-MM-DD" (required),
  "note": "note or null (required)"
}

For "delete_category" action:
{
  "name": "category name (required)"
}

For "create_multiple_expenses" action:
{
  "transactions": [
    {"amount": number, "category": "string", "date": "YYYY-MM-DD", "note": "string or null"},
    ...
  ]
}

For "create_multiple_incomes" action:
{
  "transactions": [
    {"amount": number, "source": "string", "date": "YYYY-MM-DD", "note": "string or null"},
    ...
  ]
}

=== MULTIPLE TRANSACTIONS - IMPORTANT ===
When user mentions MULTIPLE expenses/incomes in ONE message, ALWAYS use create_multiple_expenses or create_multiple_incomes.
Examples:
  User: "Add \$10 lunch and \$5 coffee"
  Response: {"type": "create_multiple_expenses", "message": "Added both expenses", "action": {"transactions": [{"amount": 10, "category": "Food", "date": "2026-05-21", "note": "lunch"}, {"amount": 5, "category": "Food", "date": "2026-05-21", "note": "coffee"}]}}
  User: "Add \$20 dinner and \$15 transport"
  Response: {"type": "create_multiple_expenses", "message": "Added both expenses", "action": {"transactions": [{"amount": 20, "category": "Food", "date": "2026-05-21", "note": "dinner"}, {"amount": 15, "category": "Transport", "date": "2026-05-21", "note": null}]}}
  User: "Add \$100 salary and \$50 freelance"
  Response: {"type": "create_multiple_incomes", "message": "Added both incomes", "action": {"transactions": [{"amount": 100, "source": "Salary", "date": "2026-05-21", "note": null}, {"amount": 50, "source": "Freelance", "date": "2026-05-21", "note": null}]}}

=== WALLET SELECTION - IMPORTANT ===
When user specifies a wallet for an expense or income, include it in the action.
Examples:
  User: "Add \$20 lunch to my Cash wallet"
  Response: {"type": "create_expense", "message": "Added \$20 lunch to Cash wallet", "action": {"amount": 20, "category": "Food", "wallet": "Cash", "date": "2026-05-21", "note": "lunch"}}
  User: "Add \$500 salary to Checking"
  Response: {"type": "create_income", "message": "Added \$500 salary to Checking wallet", "action": {"amount": 500, "source": "Salary", "wallet": "Checking", "date": "2026-05-21", "note": null}}
  User: "Can I afford \$100 dinner?" (Check wallet balance before responding)
  Response: {"type": "answer", "message": "You have \$150 in your Cash wallet, so yes you can afford it. That would leave you with \$50 remaining."}

=== WALLET TRANSFERS - IMPORTANT ===
When user wants to transfer money between wallets, use create_transfer.
Examples:
  User: "Transfer \$100 from Savings to Checking"
  Response: {"type": "create_transfer", "message": "Transferred \$100 from Savings to Checking", "action": {"amount": 100, "fromWallet": "Savings", "toWallet": "Checking", "date": "2026-05-21", "note": null}}
  User: "Move \$50 from Cash to Credit Card"
  Response: {"type": "create_transfer", "message": "Moved \$50 from Cash to Credit Card", "action": {"amount": 50, "fromWallet": "Cash", "toWallet": "Credit Card", "date": "2026-05-21", "note": null}}
  User: "Send \$200 from my Checking to Savings account"
  Response: {"type": "create_transfer", "message": "Sent \$200 from Checking to Savings", "action": {"amount": 200, "fromWallet": "Checking", "toWallet": "Savings", "date": "2026-05-21", "note": null}}

Rules:
1. If creating an expense/income and the category/source does not exist, prefer to use create_category first in a separate message, or pick the closest existing match.
2. Use today's date (${DateTime.now().toIso8601String().split('T').first}) if the user does not specify a date.
3. Return ONLY raw JSON. No markdown code blocks. No extra text outside the JSON.
4. Keep the message concise, friendly, and actionable.
5. For answer type, the action field can be omitted or null.
6. For delete actions, be as specific as possible (amount + date + note) to avoid deleting the wrong item.
7. You cannot delete default categories or categories that have transactions.
8. CRITICAL: When user mentions 2+ items in one message, use create_multiple_expenses/incomes, NEVER use create_expense/income.
9. When user specifies a wallet, use the exact wallet name from the context. If not specified, use the default wallet or ask which wallet to use.
10. For transfers, verify the source wallet has sufficient balance. If not, inform the user and ask if they want to proceed anyway.

User message: $query''';
  }

  static Map<String, dynamic> _extractChatResponse(String raw) {
    // 1. Strip markdown code blocks
    var text = raw;
    final codeBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = codeBlock.firstMatch(text);
    if (match != null) {
      text = match.group(1)!;
    }

    // 2. Try to find and parse the outermost JSON object by brace counting
    text = text.trim();
    final jsonStart = text.indexOf('{');
    if (jsonStart != -1) {
      var braceCount = 0;
      var jsonEnd = jsonStart;
      for (var i = jsonStart; i < text.length; i++) {
        if (text[i] == '{') {
          braceCount++;
        } else if (text[i] == '}') {
          braceCount--;
          if (braceCount == 0) {
            jsonEnd = i + 1;
            break;
          }
        }
      }
      if (braceCount == 0) {
        final jsonStr = text.substring(jsonStart, jsonEnd);
        try {
          final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
          if (parsed.containsKey('type') && parsed.containsKey('message')) {
            return parsed;
          }
        } catch (_) {}
      }
    }

    // 3. Fallback — treat the whole thing as an answer
    return {'type': 'answer', 'message': raw.trim()};
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

    // 2. Try to find and parse the outermost JSON object by brace counting
    text = text.trim();
    final jsonStart = text.indexOf('{');
    if (jsonStart != -1) {
      var braceCount = 0;
      var jsonEnd = jsonStart;
      for (var i = jsonStart; i < text.length; i++) {
        if (text[i] == '{') {
          braceCount++;
        } else if (text[i] == '}') {
          braceCount--;
          if (braceCount == 0) {
            jsonEnd = i + 1;
            break;
          }
        }
      }
      if (braceCount == 0) {
        final jsonStr = text.substring(jsonStart, jsonEnd);
        try {
          return jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    // 3. Fallback — return empty object
    return {};
  }
}
