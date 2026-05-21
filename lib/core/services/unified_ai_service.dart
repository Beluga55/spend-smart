import 'package:mobile_expense_tracker/core/services/gemini_ai_service.dart';
import 'package:mobile_expense_tracker/core/services/nvidia_ai_service.dart';
import 'package:mobile_expense_tracker/core/services/openrouter_ai_service.dart';

/// Unified AI service that tries OpenRouter first, then Gemini, then falls back to NVIDIA.
///
/// OpenRouter is the primary for testing speed and reliability with the openrouter/free model.
/// Gemini (Google AI Studio) is the secondary with a generous free tier (60 RPM, 1,000 RPD).
/// NVIDIA/minimax is the tertiary fallback when both are unavailable or misconfigured.
///
/// Get keys at:
/// - OpenRouter: https://openrouter.ai/keys
/// - Gemini: https://aistudio.google.com/app/apikey
/// - NVIDIA: https://build.nvidia.com/
class UnifiedAIService {
  final String? _openrouterKey;
  final String? _geminiKey;
  final String? _nvidiaKey;

  UnifiedAIService({
    String? openrouterKey,
    String? geminiKey,
    String? nvidiaKey,
  }) : _openrouterKey = openrouterKey,
       _geminiKey = geminiKey,
       _nvidiaKey = nvidiaKey;

  String? _lastUsedProvider;
  String? get lastUsedProvider => _lastUsedProvider;

  bool get isConfigured {
    final openrouter = OpenRouterAIService(_openrouterKey ?? '');
    final gemini = GeminiAIService(_geminiKey ?? '');
    final nvidia = NvidiaAIService(_nvidiaKey ?? '');
    return openrouter.isConfigured ||
        gemini.isConfigured ||
        nvidia.isConfigured;
  }

  Future<T> _tryPrimaryThenFallback<T>(
    Future<T> Function() primary,
    Future<T> Function() secondary,
    Future<T> Function() fallback,
    String operation,
  ) async {
    try {
      final result = await primary();
      _lastUsedProvider = 'OpenRouter';
      return result;
    } catch (e) {
      try {
        final result = await secondary();
        _lastUsedProvider = 'Gemini';
        return result;
      } catch (secondaryErr) {
        try {
          final result = await fallback();
          _lastUsedProvider = 'NVIDIA';
          return result;
        } catch (fallbackErr) {
          _lastUsedProvider = null;
          throw Exception(
            'AI failed on all three providers.\n'
            'OpenRouter: $e\n'
            'Gemini: $secondaryErr\n'
            'NVIDIA: $fallbackErr',
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>> parseReceipt(String ocrText) async {
    final openrouter = OpenRouterAIService(_openrouterKey ?? '');
    final gemini = GeminiAIService(_geminiKey ?? '');
    final nvidia = NvidiaAIService(_nvidiaKey ?? '');
    return _tryPrimaryThenFallback(
      () => openrouter.parseReceipt(ocrText),
      () => gemini.parseReceipt(ocrText),
      () => nvidia.parseReceipt(ocrText),
      'parseReceipt',
    );
  }

  Future<String> suggestCategory(String label, List<String> cats) async {
    final openrouter = OpenRouterAIService(_openrouterKey ?? '');
    final gemini = GeminiAIService(_geminiKey ?? '');
    final nvidia = NvidiaAIService(_nvidiaKey ?? '');
    return _tryPrimaryThenFallback(
      () => openrouter.suggestCategory(label, cats),
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
    final openrouter = OpenRouterAIService(_openrouterKey ?? '');
    final gemini = GeminiAIService(_geminiKey ?? '');
    final nvidia = NvidiaAIService(_nvidiaKey ?? '');
    return _tryPrimaryThenFallback(
      () => openrouter.generateMonthlyInsights(
        spent: spent,
        income: income,
        budget: budget,
        topCats: topCats,
        txns: txns,
      ),
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
    final openrouter = OpenRouterAIService(_openrouterKey ?? '');
    final gemini = GeminiAIService(_geminiKey ?? '');
    final nvidia = NvidiaAIService(_nvidiaKey ?? '');
    return _tryPrimaryThenFallback(
      () => openrouter.answerSpendingQuery(query, txns),
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
    final openrouter = OpenRouterAIService(_openrouterKey ?? '');
    final gemini = GeminiAIService(_geminiKey ?? '');
    final nvidia = NvidiaAIService(_nvidiaKey ?? '');
    return _tryPrimaryThenFallback(
      () => openrouter.chat(query: query, context: context, history: history),
      () => gemini.chat(query: query, context: context, history: history),
      () => nvidia.chat(query: query, context: context, history: history),
      'chat',
    );
  }
}
