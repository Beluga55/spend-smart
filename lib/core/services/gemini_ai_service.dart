import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mobile_expense_tracker/core/services/ai_prompt.dart';

class GeminiAIService {
  final String apiKey;
  static const String _model = 'gemini-2.5-flash';

  GeminiAIService(this.apiKey);

  bool get isConfigured =>
      apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_KEY_HERE';

  Future<String> _generate(
    String prompt, {
    double temp = 0.05,
    int tokens = 512,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'Gemini API key not configured. Add GEMINI_API_KEY to .env',
      );
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': temp,
        'maxOutputTokens': tokens,
        'thinkingConfig': {'thinkingBudget': 0},
      },
    });

    final res = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Gemini request timed out after 15s');
          },
        );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final parts =
          data['candidates']?[0]?['content']?['parts'] as List<dynamic>?;
      if (parts != null && parts.isNotEmpty) {
        for (int i = parts.length - 1; i >= 0; i--) {
          final part = parts[i] as Map<String, dynamic>;
          if (part.containsKey('text') &&
              !part.containsKey('thoughtSignature')) {
            final text = part['text'] as String;
            if (text.trim().isNotEmpty) return text;
          }
        }
        final text = parts.last['text'] as String?;
        if (text != null && text.trim().isNotEmpty) return text;
      }
      throw Exception('Gemini returned empty content');
    }

    String errorMsg = 'Gemini API ${res.statusCode}';
    try {
      final errData = jsonDecode(res.body) as Map<String, dynamic>;
      errorMsg = errData['error']?['message'] ?? res.body;
    } catch (_) {
      errorMsg = res.body;
    }
    throw HttpException('Gemini API ${res.statusCode}: $errorMsg');
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

    final raw = await _generate(prompt, temp: 0.05, tokens: 512);
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
    return (await _generate(prompt, temp: 0.05, tokens: 64)).trim();
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
    return _generate(prompt, temp: 0.3, tokens: 256);
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
    return (await _generate(prompt, temp: 0.2, tokens: 256)).trim();
  }

  Future<Map<String, dynamic>> chat({
    required String query,
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> history,
  }) async {
    final prompt = buildChatPrompt(query, context, history);
    final raw = await _generate(prompt, temp: 0.2, tokens: 1024);
    return extractChatResponse(raw);
  }

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
    if (!isConfigured) {
      throw Exception(
        'Gemini API key not configured. Add GEMINI_API_KEY to .env',
      );
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:streamGenerateContent?alt=sse&key=$apiKey',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': temp,
        'maxOutputTokens': tokens,
        'thinkingConfig': {'thinkingBudget': 0},
      },
    });

    final client = http.Client();
    try {
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.body = body;

      final response = await client.send(request).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Gemini streaming request timed out');
        },
      );

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw Exception('Gemini API ${response.statusCode}: $errorBody');
      }

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data.isEmpty) continue;

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final parts =
                  json['candidates']?[0]?['content']?['parts'] as List<dynamic>?;
              if (parts != null) {
                for (final part in parts) {
                  final text = (part as Map<String, dynamic>)['text'] as String?;
                  if (text != null && text.isNotEmpty) {
                    yield text;
                  }
                }
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
