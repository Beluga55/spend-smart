import 'package:mobile_expense_tracker/core/services/gemini_ai_service.dart';
import 'package:mobile_expense_tracker/core/services/nvidia_ai_service.dart';

/// Unified AI service that tries Gemini first, then falls back to NVIDIA/minimax.
///
/// Gemini (Google AI Studio) is the primary because it has a generous free tier
/// (60 RPM, 1,000 RPD) and stronger instruction-following for structured output.
/// NVIDIA/minimax is the fallback when Gemini is unavailable or misconfigured.
///
/// Get a free Gemini key at: https://aistudio.google.com/app/apikey
class UnifiedAIService {
  final String? _geminiKey;
  final String? _nvidiaKey;

  UnifiedAIService({String? geminiKey, String? nvidiaKey})
      : _geminiKey = geminiKey,
        _nvidiaKey = nvidiaKey;

  String? _lastUsedProvider;
  String? get lastUsedProvider => _lastUsedProvider;

  bool get isConfigured {
    final gemini = GeminiAIService(_geminiKey ?? '');
    final nvidia = NvidiaAIService(_nvidiaKey ?? '');
    return gemini.isConfigured || nvidia.isConfigured;
  }

  Future<T> _tryPrimaryThenFallback<T>(
    Future<T> Function() primary,
    Future<T> Function() fallback,
    String operation,
  ) async {
    try {
      final result = await primary();
      _lastUsedProvider = 'Gemini';
      return result;
    } catch (e) {
      try {
        final result = await fallback();
        _lastUsedProvider = 'NVIDIA';
        return result;
      } catch (fallbackErr) {
        _lastUsedProvider = null;
        throw Exception(
          'AI failed on both providers.\n'
          'Gemini: $e\n'
          'NVIDIA: $fallbackErr',
        );
      }
    }
  }

  Future<Map<String, dynamic>> parseReceipt(String ocrText) async {
    final gemini = GeminiAIService(_geminiKey ?? '');
    final nvidia = NvidiaAIService(_nvidiaKey ?? '');
    return _tryPrimaryThenFallback(
      () => gemini.parseReceipt(ocrText),
      () => nvidia.parseReceipt(ocrText),
      'parseReceipt',
    );
  }

  Future<String> suggestCategory(String label, List<String> cats) async {
    final gemini = GeminiAIService(_geminiKey ?? '');
    final nvidia = NvidiaAIService(_nvidiaKey ?? '');
    return _tryPrimaryThenFallback(
      () => gemini.suggestCategory(label, cats),
      () => nvidia.suggestCategory(label, cats),
      'suggestCategory',
    );
  }

  Future<String> generateMonthlyInsights({
    required double spent,
    required double income,
    required double budget,
    required List<Map<String, dynamic>> topCats,
    required int txns,
  }) async {
    final gemini = GeminiAIService(_geminiKey ?? '');
    final nvidia = NvidiaAIService(_nvidiaKey ?? '');
    return _tryPrimaryThenFallback(
      () => gemini.generateMonthlyInsights(
        spent: spent,
        income: income,
        budget: budget,
        topCats: topCats,
        txns: txns,
      ),
      () => nvidia.generateMonthlyInsights(
        spent: spent,
        income: income,
        budget: budget,
        topCats: topCats,
        txns: txns,
      ),
      'generateMonthlyInsights',
    );
  }

  Future<String?> answerSpendingQuery(
    String query,
    List<Map<String, dynamic>> txns,
  ) async {
    final gemini = GeminiAIService(_geminiKey ?? '');
    final nvidia = NvidiaAIService(_nvidiaKey ?? '');
    return _tryPrimaryThenFallback(
      () => gemini.answerSpendingQuery(query, txns),
      () => nvidia.answerSpendingQuery(query, txns),
      'answerSpendingQuery',
    );
  }

  Future<Map<String, dynamic>> chat({
    required String query,
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> history,
  }) async {
    final gemini = GeminiAIService(_geminiKey ?? '');
    final nvidia = NvidiaAIService(_nvidiaKey ?? '');
    return _tryPrimaryThenFallback(
      () => gemini.chat(query: query, context: context, history: history),
      () => nvidia.chat(query: query, context: context, history: history),
      'chat',
    );
  }
}
