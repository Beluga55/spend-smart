import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/core/models/income.dart';
import 'package:mobile_expense_tracker/core/models/wallet.dart';

class HomeWidgetService {
  static const String _widgetName = 'SpendSmartWidget';

  static Future<void> initialize() async {
    await HomeWidget.registerInteractivityCallback(interactivityCallback);
  }

  static Future<void> updateBalanceWidget() async {
    try {
      final walletBox = Hive.box<Wallet>('wallets');
      final totalBalance = walletBox.values.fold<double>(
        0,
        (sum, w) => sum + _getWalletBalance(w.id),
      );

      final today = DateTime.now();
      final expenseBox = Hive.box<Expense>('expenses');
      final todayExpenses = expenseBox.values
          .where(
            (e) =>
                e.date.year == today.year &&
                e.date.month == today.month &&
                e.date.day == today.day,
          )
          .fold<double>(0, (sum, e) => sum + e.amount);

      final incomeBox = Hive.box<Income>('incomes');
      final todayIncome = incomeBox.values
          .where(
            (i) =>
                i.date.year == today.year &&
                i.date.month == today.month &&
                i.date.day == today.day,
          )
          .fold<double>(0, (sum, i) => sum + i.amount);

      await HomeWidget.saveWidgetData<String>(
        '${_widgetName}_balance',
        totalBalance.toStringAsFixed(2),
      );
      await HomeWidget.saveWidgetData<String>(
        '${_widgetName}_todaySpent',
        todayExpenses.toStringAsFixed(2),
      );
      await HomeWidget.saveWidgetData<String>(
        '${_widgetName}_todayIncome',
        todayIncome.toStringAsFixed(2),
      );
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );
    } catch (e) {
      debugPrint('[HomeWidget] Update error: $e');
    }
  }

  static double _getWalletBalance(String walletId) {
    final expenseBox = Hive.box<Expense>('expenses');
    final incomeBox = Hive.box<Income>('incomes');

    final totalExpenses = expenseBox.values
        .where((e) => e.walletId == walletId)
        .fold<double>(0, (sum, e) => sum + e.amount);

    final totalIncome = incomeBox.values
        .where((i) => i.walletId == walletId)
        .fold<double>(0, (sum, i) => sum + i.amount);

    return totalIncome - totalExpenses;
  }

  @pragma('vm:entry-point')
  static Future<void> interactivityCallback(Uri? uri) async {
    // Widget was tapped — the app opens automatically.
    // The URI can be used to deep-link to a specific screen.
    if (uri != null) {
      debugPrint('[HomeWidget] Interacted with URI: $uri');
    }
  }
}
