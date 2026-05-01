import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/services/currency_converter_service.dart';
import 'package:mobile_expense_tracker/core/constants/currency_constants.dart';

final currencyConverterServiceProvider = Provider<CurrencyConverterService>((ref) {
  return CurrencyConverterService();
});

class CurrencyConverterState {
  final String fromCurrency;
  final String toCurrency;
  final double amount;
  final double result;
  final Map<String, double> rates;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const CurrencyConverterState({
    this.fromCurrency = 'USD',
    this.toCurrency = 'CNY',
    this.amount = 0,
    this.result = 0,
    this.rates = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  CurrencyConverterState copyWith({
    String? fromCurrency,
    String? toCurrency,
    double? amount,
    double? result,
    Map<String, double>? rates,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    bool clearError = false,
  }) {
    return CurrencyConverterState(
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      amount: amount ?? this.amount,
      result: result ?? this.result,
      rates: rates ?? this.rates,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class CurrencyConverterNotifier extends StateNotifier<CurrencyConverterState> {
  final CurrencyConverterService _service;

  CurrencyConverterNotifier(this._service) : super(const CurrencyConverterState());

  Future<void> init() async {
    await _service.init();
    await refreshRates();
  }

  Future<void> refreshRates() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final rates = await _service.fetchRates(state.fromCurrency);
      final result = _service.convert(state.amount, state.fromCurrency, state.toCurrency, rates);

      state = state.copyWith(
        rates: rates,
        result: result,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      final cached = _service.getCachedRates(state.fromCurrency);
      if (cached != null) {
        final result = _service.convert(state.amount, state.fromCurrency, state.toCurrency, cached);
        state = state.copyWith(
          rates: cached,
          result: result,
          isLoading: false,
          error: 'Using cached rates (API unavailable)',
          lastUpdated: DateTime.now(),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch rates',
        );
      }
    }
  }

  void setFromCurrency(String currency) {
    if (currency == state.fromCurrency) return;

    state = state.copyWith(fromCurrency: currency);
    _recalculate();
    refreshRates();
  }

  void setToCurrency(String currency) {
    if (currency == state.toCurrency) return;

    state = state.copyWith(toCurrency: currency);
    _recalculate();
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
    _recalculate();
  }

  void swapCurrencies() {
    final temp = state.fromCurrency;
    state = state.copyWith(
      fromCurrency: state.toCurrency,
      toCurrency: temp,
    );
    _recalculate();
  }

  void _recalculate() {
    if (state.rates.isEmpty) return;
    final result = _service.convert(
      state.amount,
      state.fromCurrency,
      state.toCurrency,
      state.rates,
    );
    state = state.copyWith(result: result);
  }
}

final currencyConverterProvider =
    StateNotifierProvider<CurrencyConverterNotifier, CurrencyConverterState>((ref) {
  final service = ref.watch(currencyConverterServiceProvider);
  return CurrencyConverterNotifier(service);
});

final currencyListProvider = Provider<List<Currency>>((ref) {
  return CurrencyConstants.currencies;
});