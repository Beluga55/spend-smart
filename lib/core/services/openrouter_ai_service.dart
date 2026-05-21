import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:mobile_expense_tracker/core/services/ai_prompt.dart';

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
    if (apiKey.isEmpty) {
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

    if (response.statusCode != 200) {
      throw Exception(
        'OpenRouter API error: ${response.statusCode} - ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['choices']?[0]?['message']?['content'] as String? ?? '';
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
    return extractJson(raw);
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
    final prompt = buildChatPrompt(query, context, history);
    final raw = await _generate(prompt, temp: 0.2, tokens: 1024);
    debugPrint('[OpenRouter] chat response: $raw');
    return extractChatResponse(raw);
  }

  /// Stream the chat response token by token.
  /// Yields content chunks as they arrive from the API.
  Stream<String> chatStream({
    required String query,
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> history,
  }) {
    final prompt = buildChatPrompt(query, context, history);

    return _streamGenerate(prompt, temp: 0.2, tokens: 1024);
  }

  Stream<String> _streamGenerate(
    String prompt, {
    double temp = 0.2,
    int tokens = 1024,
  }) async* {
    if (apiKey.isEmpty) {
      throw Exception('OpenRouter API key is not configured');
    }

    final headers = await _getHeaders();
    final client = http.Client();

    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/chat/completions'));
      request.headers.addAll(headers);
      request.body = jsonEncode({
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
        'stream': true,
      });

      final response = await client.send(request);

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception(
          'OpenRouter API error: ${response.statusCode} - $body',
        );
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
