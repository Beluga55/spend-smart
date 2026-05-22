import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/features/dashboard/widgets/summary_card.dart';
import 'package:mobile_expense_tracker/features/dashboard/widgets/budget_progress.dart';
import 'package:mobile_expense_tracker/features/dashboard/widgets/category_chart.dart';
import 'package:mobile_expense_tracker/features/dashboard/widgets/recent_expenses.dart';
import 'package:mobile_expense_tracker/features/dashboard/widgets/spending_trends.dart';
import 'package:mobile_expense_tracker/features/dashboard/widgets/top_categories.dart';
import 'package:mobile_expense_tracker/features/dashboard/widgets/streak_banner.dart';
import 'package:mobile_expense_tracker/features/dashboard/widgets/ai_insights_card.dart';
import 'package:mobile_expense_tracker/features/dashboard/widgets/month_selector.dart';
import 'package:mobile_expense_tracker/features/dashboard/widgets/quick_add_sheet.dart';
import 'package:mobile_expense_tracker/features/budget/budget_modal.dart';
import 'package:mobile_expense_tracker/features/expenses/widgets/expense_modal.dart';
import 'package:mobile_expense_tracker/features/income/widgets/income_modal.dart';
import 'package:mobile_expense_tracker/features/settings/settings_screen.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthlyTotal = ref.watch(monthlyTotalProvider);
    final budgetProgress = ref.watch(globalBudgetProgressProvider);
    final globalBudget = ref.watch(globalBudgetProvider);
    final categories = ref.watch(expenseCategoriesProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final budgetAlerts = ref.watch(budgetAlertProvider);

    final displayBudget = globalBudget?.limitAmount ?? 0;

    final dividerColor = Theme.of(context).colorScheme.outline;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 108,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Icon(Icons.menu, size: 24),
            ),
          ),
        ),
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => _showBudgetModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StreakBanner(),
            MonthSelector(
              selectedMonth: selectedMonth,
              onMonthChanged: (month) {
                ref.read(selectedMonthProvider.notifier).state = month;
              },
            ),
            const SizedBox(height: 16),

            const AIInsightsCard(),

            if (budgetAlerts.isNotEmpty)
              ...budgetAlerts.entries.map(
                (alert) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        alert.value.contains('exceeded')
                            ? Icons.error_outline
                            : Icons.warning_amber_outlined,
                        color: textPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.value,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SummaryCard(
              title: DateFormat('MMMM yyyy').format(selectedMonth),
              budget: displayBudget > 0 ? displayBudget : null,
            ),

            if (displayBudget > 0) ...[
              const SizedBox(height: 16),
              BudgetProgressCard(
                progress: budgetProgress,
                budgetAmount: displayBudget,
                currentAmount: monthlyTotal,
              ),
            ],

            const SizedBox(height: 24),
            _SectionHeader(
              title: l10n.spendingByCategory,
              textPrimary: textPrimary,
            ),
            const SizedBox(height: 12),
            CategoryChart(
              categoryTotals: categoryTotals,
              categories: categories,
            ),

            const SizedBox(height: 24),
            const TopCategoriesList(),

            const SizedBox(height: 24),
            const SpendingTrendsChart(),

            const SizedBox(height: 24),
            _SectionHeader(
              title: l10n.recentTransactions,
              textPrimary: textPrimary,
            ),
            const SizedBox(height: 12),
            const RecentTransactionsList(),

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboard_fab',
        onPressed: () => _showQuickAddSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickAddSheet(
        onAction: (action) {
          switch (action) {
            case QuickAddAction.expense:
              _showAddExpenseModal(context, ref);
              break;
            case QuickAddAction.income:
              _showAddIncomeModal(context, ref);
              break;
          }
        },
      ),
    );
  }

  void _showBudgetModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BudgetModal(),
    );
  }

  void _showAddExpenseModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseModal(
        onSave: (amount, categoryId, date, note, walletId, receiptImagePath) {
          ref
              .read(expensesProvider.notifier)
              .addExpense(
                amount: amount,
                categoryId: categoryId,
                date: date,
                note: note,
                walletId: walletId,
                receiptImagePath: receiptImagePath,
              );
          final selected = ref.read(selectedMonthProvider);
          if (date.year != selected.year || date.month != selected.month) {
            ref.read(selectedMonthProvider.notifier).state = DateTime(
              date.year,
              date.month,
            );
          }
        },
      ),
    );
  }

  void _showAddIncomeModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncomeModal(
        onSave: (amount, source, date, note, walletId) {
          ref
              .read(incomesProvider.notifier)
              .addIncome(
                amount: amount,
                source: source,
                date: date,
                note: note,
                walletId: walletId,
              );
          final selected = ref.read(selectedMonthProvider);
          if (date.year != selected.year || date.month != selected.month) {
            ref.read(selectedMonthProvider.notifier).state = DateTime(
              date.year,
              date.month,
            );
          }
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color textPrimary;

  const _SectionHeader({required this.title, required this.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    );
  }
}
