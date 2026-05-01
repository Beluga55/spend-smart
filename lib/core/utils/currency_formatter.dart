import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';

String formatCurrency(double amount, WidgetRef ref) {
  final currency = ref.watch(currencyProvider);
  return '${currency.symbol}${amount.toStringAsFixed(2)}';
}

String formatCurrencyCompact(double amount, WidgetRef ref) {
  final currency = ref.watch(currencyProvider);
  if (amount >= 1000000) {
    return '${currency.symbol}${(amount / 1000000).toStringAsFixed(1)}M';
  } else if (amount >= 1000) {
    return '${currency.symbol}${(amount / 1000).toStringAsFixed(1)}K';
  }
  return '${currency.symbol}${amount.toStringAsFixed(2)}';
}