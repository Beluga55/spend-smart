import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/constants/app_constants.dart';
import 'package:mobile_expense_tracker/core/services/unified_ai_service.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/core/models/category.dart' as models;

enum AIFeature { receiptParsing, autoCategorize, monthlyInsights, chatQuery }

class AISettings {
  final String geminiApiKey;
  final String nvidiaApiKey;
  final Set<AIFeature> enabledFeatures;

  const AISettings({
    this.geminiApiKey = '',
    this.nvidiaApiKey = '',
    this.enabledFeatures = const {
      AIFeature.receiptParsing,
      AIFeature.autoCategorize,
      AIFeature.monthlyInsights,
    },
  });

  AISettings copyWith({
    String? geminiApiKey,
    String? nvidiaApiKey,
    Set<AIFeature>? enabledFeatures,
  }) {
    return AISettings(
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      nvidiaApiKey: nvidiaApiKey ?? this.nvidiaApiKey,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
    );
  }

  Map<String, dynamic> toJson() => {
    'geminiApiKey': geminiApiKey,
    'nvidiaApiKey': nvidiaApiKey,
    'enabledFeatures': enabledFeatures.map((f) => f.name).toList(),
  };

  factory AISettings.fromJson(Map<String, dynamic> json) {
    final features = (json['enabledFeatures'] as List<dynamic>?)
            ?.map((f) => AIFeature.values.firstWhere(
                  (e) => e.name == f,
                  orElse: () => AIFeature.receiptParsing,
                ))
            .toSet() ??
        const {AIFeature.receiptParsing, AIFeature.autoCategorize};
    return AISettings(
      geminiApiKey: json['geminiApiKey'] as String? ?? '',
      nvidiaApiKey: json['nvidiaApiKey'] as String? ?? '',
      enabledFeatures: features,
    );
  }

  bool get hasAnyKey {
    final g = geminiApiKey.isNotEmpty && geminiApiKey != AppConstants.geminiApiKeyPlaceholder;
    final n = nvidiaApiKey.isNotEmpty && nvidiaApiKey != AppConstants.nvidiaApiKeyPlaceholder;
    return g || n;
  }

  String get activeProviderLabel {
    final g = geminiApiKey.isNotEmpty && geminiApiKey != AppConstants.geminiApiKeyPlaceholder;
    if (g) return 'Gemini';
    final n = nvidiaApiKey.isNotEmpty && nvidiaApiKey != AppConstants.nvidiaApiKeyPlaceholder;
    if (n) return 'NVIDIA';
    return 'none';
  }
}

class AINotifier extends StateNotifier<AISettings> {
  AINotifier() : super(_loadSettings());

  static AISettings _loadSettings() {
    try {
      final box = Hive.box('settings');
      final raw = box.get('aiSettings');
      final data = raw is Map ? Map<String, dynamic>.from(raw) : null;
      if (data != null) {
        final loaded = AISettings.fromJson(data);
        // Fall back to env defaults if user cleared the fields.
        return loaded.copyWith(
          geminiApiKey: loaded.geminiApiKey.isEmpty ? AppConstants.geminiApiKey : loaded.geminiApiKey,
          nvidiaApiKey: loaded.nvidiaApiKey.isEmpty ? AppConstants.nvidiaApiKey : loaded.nvidiaApiKey,
        );
      }
    } catch (_) {}
    return AISettings(
      geminiApiKey: AppConstants.geminiApiKey,
      nvidiaApiKey: AppConstants.nvidiaApiKey,
    );
  }

  Future<void> saveSettings(AISettings settings) async {
    state = settings;
    final box = Hive.box('settings');
    await box.put('aiSettings', settings.toJson());
  }

  Future<void> updateGeminiApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    final effective = trimmed.isEmpty ? AppConstants.geminiApiKey : trimmed;
    await saveSettings(state.copyWith(geminiApiKey: effective));
  }

  Future<void> updateNvidiaApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    final effective = trimmed.isEmpty ? AppConstants.nvidiaApiKey : trimmed;
    await saveSettings(state.copyWith(nvidiaApiKey: effective));
  }

  Future<void> toggleFeature(AIFeature feature, bool enabled) async {
    final features = Set<AIFeature>.from(state.enabledFeatures);
    if (enabled) {
      features.add(feature);
    } else {
      features.remove(feature);
    }
    await saveSettings(state.copyWith(enabledFeatures: features));
  }

  UnifiedAIService get service => UnifiedAIService(
        geminiKey: state.geminiApiKey,
        nvidiaKey: state.nvidiaApiKey,
      );
}

final aiSettingsProvider =
    StateNotifierProvider<AINotifier, AISettings>((ref) {
  return AINotifier();
});

final aiServiceProvider = Provider<UnifiedAIService>((ref) {
  return ref.watch(aiSettingsProvider.notifier).service;
});

// ── AI Insights Caching ──

class AIInsightsCache {
  final String insight;
  final String monthKey;
  final int cachedAt;
  final String? provider;

  AIInsightsCache({
    required this.insight,
    required this.monthKey,
    required this.cachedAt,
    this.provider,
  });

  Map<String, dynamic> toJson() => {
        'insight': insight,
        'monthKey': monthKey,
        'cachedAt': cachedAt,
        'provider': provider,
      };

  factory AIInsightsCache.fromJson(Map<String, dynamic> json) => AIInsightsCache(
        insight: json['insight'] as String,
        monthKey: json['monthKey'] as String,
        cachedAt: json['cachedAt'] as int,
        provider: json['provider'] as String?,
      );
}

class AIInsightsNotifier extends StateNotifier<AsyncValue<String?>> {
  AIInsightsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;
  String? _lastProvider;
  String? get lastProvider => _lastProvider;

  static const _cacheKey = 'aiInsightCache';
  static const _dismissedKey = 'aiInsightDismissedMonth';
  static const _cacheDurationMs = 6 * 60 * 60 * 1000; // 6 hours

  String get _currentMonthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> _init() async {
    try {
      final settings = Hive.box('settings');

      final dismissedMonth = settings.get(_dismissedKey) as String?;
      if (dismissedMonth == _currentMonthKey) {
        state = const AsyncValue.data(null);
        return;
      }

      final raw = settings.get(_cacheKey);
      final cacheData = raw is Map ? Map<String, dynamic>.from(raw) : null;
      if (cacheData != null) {
        try {
          final cache = AIInsightsCache.fromJson(cacheData);
          final age = DateTime.now().millisecondsSinceEpoch - cache.cachedAt;
          if (cache.monthKey == _currentMonthKey && age < _cacheDurationMs) {
            _lastProvider = cache.provider;
            state = AsyncValue.data(cache.insight);
            return;
          }
        } catch (_) {}
      }

      await refresh();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();

    // Clear dismissed state so user can re-trigger manually
    final settings = Hive.box('settings');
    await settings.delete(_dismissedKey);

    final aiSettings = _ref.read(aiSettingsProvider);
    if (!aiSettings.enabledFeatures.contains(AIFeature.monthlyInsights) ||
        !aiSettings.hasAnyKey) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final service = _ref.read(aiSettingsProvider.notifier).service;
      final monthlyExpenses = _ref.read(monthlyExpensesProvider);
      final monthlyIncomes = _ref.read(monthlyIncomesProvider);
      final globalBudget = _ref.read(globalBudgetProvider);
      final categories = _ref.read(categoriesProvider);

      final totalSpent = monthlyExpenses.fold<double>(0, (s, e) => s + e.amount);
      final totalIncome = monthlyIncomes.fold<double>(0, (s, i) => s + i.amount);
      final budgetAmount = globalBudget?.limitAmount ?? 0;
      final transactionCount = monthlyExpenses.length;

      final categoryTotals = <String, double>{};
      for (final e in monthlyExpenses) {
        categoryTotals[e.categoryId] =
            (categoryTotals[e.categoryId] ?? 0) + e.amount;
      }

      final sortedCats = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topCategories = sortedCats.take(5).map((e) {
        final cat = categories.firstWhere(
          (c) => c.id == e.key,
          orElse: () => models.Category(
            id: '',
            name: 'Unknown',
            iconName: 'help_outline',
            color: 0xFF999999,
            isDefault: true,
            categoryType: 'expense',
          ),
        );
        return {
          'name': cat.name,
          'amount': e.value,
          'percentage': totalSpent > 0
              ? double.parse((e.value / totalSpent * 100).toStringAsFixed(1))
              : 0,
        };
      }).toList();

      final insight = await service.generateMonthlyInsights(
        spent: totalSpent,
        income: totalIncome,
        budget: budgetAmount,
        topCats: topCategories,
        txns: transactionCount,
      );
      _lastProvider = service.lastUsedProvider;

      final cache = AIInsightsCache(
        insight: insight,
        monthKey: _currentMonthKey,
        cachedAt: DateTime.now().millisecondsSinceEpoch,
        provider: _lastProvider,
      );
      final settings = Hive.box('settings');
      await settings.put(_cacheKey, cache.toJson());
      await settings.delete(_dismissedKey);

      state = AsyncValue.data(insight);
    } catch (e, stack) {
      developer.log('[AI Insights] Error: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> dismiss() async {
    final settings = Hive.box('settings');
    await settings.put(_dismissedKey, _currentMonthKey);
    _lastProvider = null;
    state = const AsyncValue.data(null);
  }
}

final aiInsightsProvider =
    StateNotifierProvider<AIInsightsNotifier, AsyncValue<String?>>((ref) {
  ref.keepAlive();
  return AIInsightsNotifier(ref);
});
