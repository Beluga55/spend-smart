import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mobile_expense_tracker/core/services/ai_prompt.dart';

class NvidiaAIService {
  final String apiKey;
  static const String _baseUrl = 'https://integrate.api.nvidia.com/v1';
  static const String _model = 'minimaxai/minimax-m2.7';

  NvidiaAIService(this.apiKey);

  bool get isConfigured => apiKey.isNotEmpty && apiKey != 'nvapi-YOUR_KEY_HERE';

  Future<String> _chat(
    String text, {
    double temp = 0.2,
    int tokens = 512,
  }) async {
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

    final res = await http
        .post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('NVIDIA request timed out after 15s');
          },
        );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['choices']?[0]?['message']?['content'] as String? ?? '';
    }
    throw HttpException('NVIDIA API ${res.statusCode}: ${res.body}');
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
    return extractJson(raw);
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
    final cats = topCats
        .map((c) => '${c['name']}: \$${c['amount']}')
        .join('\n');
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

  Future<Map<String, dynamic>> chat({
    required String query,
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> history,
  }) async {
    final prompt = buildChatPrompt(query, context, history);
    final raw = await _chat(prompt, temp: 0.2, tokens: 1024);
    return extractChatResponse(raw);
  }

  Stream<String> chatStream({
    required String query,
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> history,
  }) {
    final prompt = buildChatPrompt(query, context, history);
    return _streamChat(prompt, temp: 0.2, tokens: 1024);
  }

  Stream<String> _streamChat(
    String text, {
    double temp = 0.2,
    int tokens = 1024,
  }) async* {
    if (!isConfigured) {
      throw Exception('API key not configured. Add NVIDIA_API_KEY to .env');
    }

    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/chat/completions'));
      request.headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      });
      request.body = jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': text},
        ],
        'temperature': temp,
        'max_tokens': tokens,
        'stream': true,
      });

      final response = await client.send(request).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('NVIDIA streaming request timed out');
        },
      );

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw Exception('NVIDIA API ${response.statusCode}: $errorBody');
      }

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') return;
            if (data.isEmpty) continue;

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final content = json['choices']?[0]?['delta']?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            } catch (_) {}
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
