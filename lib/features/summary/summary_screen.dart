import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final expenses = ref.watch(expensesProvider);
    final categories = ref.watch(categoriesProvider);
    final globalBudget = ref.watch(globalBudgetProvider);

    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    final currentMonthExpenses = expenses.where((e) =>
      e.date.month == _selectedMonth.month && e.date.year == _selectedMonth.year
    ).toList();

    final previousMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    final previousMonthExpenses = expenses.where((e) =>
      e.date.month == previousMonth.month && e.date.year == previousMonth.year
    ).toList();

    final currentTotal = currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final previousTotal = previousMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final percentChange = previousTotal > 0 ? ((currentTotal - previousTotal) / previousTotal * 100) : 0.0;

    final weeklySpending = _calculateWeeklySpending(currentMonthExpenses);
    final topCategories = _getTopCategories(currentMonthExpenses, categories, 3);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.monthlySummary),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelector(l10n, textPrimary, textSecondary, surfaceColor),
            const SizedBox(height: 20),
            _buildTotalSpendingCard(
              currentTotal,
              currency.symbol,
              percentChange,
              l10n,
              isDark,
              textPrimary,
              textSecondary,
              surfaceColor,
            ),
            const SizedBox(height: 16),
            _buildWeekBreakdown(
              weeklySpending,
              currency.symbol,
              l10n,
              isDark,
              textPrimary,
              textSecondary,
              surfaceColor,
            ),
            const SizedBox(height: 16),
            _buildTopCategories(
              topCategories,
              currentMonthExpenses,
              currency.symbol,
              l10n,
              isDark,
              textPrimary,
              textSecondary,
              surfaceColor,
            ),
            const SizedBox(height: 16),
            _buildBudgetSummary(
              globalBudget?.limitAmount ?? 0,
              currentTotal,
              currency.symbol,
              l10n,
              isDark,
              textPrimary,
              textSecondary,
              surfaceColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(
    AppLocalizations l10n,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
  ) {
    final monthFormat = DateFormat('MMMM yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: textPrimary),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
          ),
          Text(
            monthFormat.format(_selectedMonth),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: textPrimary),
            onPressed: _selectedMonth.month < DateTime.now().month ||
                      _selectedMonth.year < DateTime.now().year
                ? () {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSpendingCard(
    double total,
    String currencySymbol,
    double percentChange,
    AppLocalizations l10n,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
  ) {
    final isIncrease = percentChange > 0;
    final changeColor = isIncrease ? Colors.red : Colors.green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.monthlySpending,
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol${total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (percentChange != 0)
            Row(
              children: [
                Icon(
                  isIncrease ? Icons.trending_up : Icons.trending_down,
                  color: changeColor,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${percentChange.abs().toStringAsFixed(1)}% ${l10n.vsLastMonth}',
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildWeekBreakdown(
    List<double> weeklySpending,
    String currencySymbol,
    AppLocalizations l10n,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
  ) {
    final maxSpending = weeklySpending.isEmpty ? 1.0 : weeklySpending.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(weeklySpending.length, (index) {
            final weekNum = index + 1;
            final spending = weeklySpending[index];
            final percentage = maxSpending > 0 ? spending / maxSpending : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.week(weekNum),
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$currencySymbol${spending.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: textSecondary.withAlpha(26),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.white : AppTheme.primaryColor,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopCategories(
    List<MapEntry<String, double>> topCategories,
    List<Expense> expenses,
    String currencySymbol,
    AppLocalizations l10n,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
  ) {
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.topCategories,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (topCategories.isEmpty)
            Text(
              l10n.noSpendingDataYet,
              style: TextStyle(color: textSecondary),
            )
          else
            ...topCategories.map((entry) {
              final categoryId = entry.key;
              final spending = entry.value;
              final percentage = total > 0 ? (spending / total * 100) : 0.0;

              final category = ref.watch(categoriesProvider).firstWhere(
                (c) => c.id == categoryId,
                orElse: () => throw Exception('Category not found'),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(category.color).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        IconConstants.getIcon(category.iconName),
                        color: Color(category.color),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$currencySymbol${spending.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBudgetSummary(
    double budgetLimit,
    double currentSpending,
    String currencySymbol,
    AppLocalizations l10n,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
  ) {
    final isOverBudget = budgetLimit > 0 && currentSpending > budgetLimit;
    final remaining = budgetLimit - currentSpending;
    final percentage = budgetLimit > 0 ? (currentSpending / budgetLimit * 100).clamp(0, 100) : 0.0;

    if (budgetLimit <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.budgetSummary,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currencySymbol${currentSpending.toStringAsFixed(0)} / $currencySymbol${budgetLimit.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverBudget
                      ? Colors.red.withAlpha(25)
                      : Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOverBudget ? l10n.isOverBudget : l10n.onTrack,
                  style: TextStyle(
                    color: isOverBudget ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: textSecondary.withAlpha(26),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget
                    ? Colors.red
                    : (isDark ? Colors.white : AppTheme.primaryColor),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isOverBudget
                ? '${l10n.isOverBudget} $currencySymbol${remaining.abs().toStringAsFixed(0)}'
                : '${l10n.remaining} $currencySymbol${remaining.toStringAsFixed(0)}',
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<double> _calculateWeeklySpending(List<Expense> expenses) {
    if (expenses.isEmpty) return [0, 0, 0, 0];

    final weeklyTotals = [0.0, 0.0, 0.0, 0.0];

    for (final expense in expenses) {
      final day = expense.date.day;
      final weekIndex = ((day - 1) / 7).floor().clamp(0, 3);
      weeklyTotals[weekIndex] += expense.amount;
    }

    return weeklyTotals;
  }

  List<MapEntry<String, double>> _getTopCategories(
    List<Expense> expenses,
    List categories,
    int count,
  ) {
    final totals = <String, double>{};

    for (final expense in expenses) {
      totals[expense.categoryId] = (totals[expense.categoryId] ?? 0) + expense.amount;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(count).toList();
  }
}
