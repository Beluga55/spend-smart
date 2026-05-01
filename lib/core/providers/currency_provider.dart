import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/constants/currency_constants.dart';

final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  final box = Hive.box('settings');
  return CurrencyNotifier(box);
});

class CurrencyNotifier extends StateNotifier<Currency> {
  final Box _box;

  CurrencyNotifier(this._box) : super(CurrencyConstants.currencies.first) {
    _loadCurrency();
  }

  void _loadCurrency() {
    final currencyCode = _box.get('currencyCode', defaultValue: 'USD');
    state = CurrencyConstants.getCurrency(currencyCode);
  }

  Future<void> setCurrency(String currencyCode) async {
    await _box.put('currencyCode', currencyCode);
    state = CurrencyConstants.getCurrency(currencyCode);
  }
}