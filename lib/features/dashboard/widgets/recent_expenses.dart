import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/core/models/income.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/features/income/widgets/income_modal.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final categories = ref.watch(categoriesProvider);
    final recentExpenses = ref.watch(recentExpensesProvider);
    final recentIncomes = ref.watch(recentIncomesProvider);

    final cs = Theme.of(context).colorScheme;
    final surfaceColor = cs.surface;
    final dividerColor = cs.outline;
    final textPrimary = cs.onSurface;
    final textSecondary = cs.onSurface.withAlpha(153);

    final items = <_RecentItem>[
      ...recentExpenses.map((e) => _RecentItem.fromExpense(e)),
      ...recentIncomes.map((i) => _RecentItem.fromIncome(i)),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final display = items.take(5).toList();

    if (display.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor),
        ),
        child: Center(
          child: Text(l10n.noExpensesYet, style: TextStyle(color: textSecondary)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: display.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: dividerColor),
        itemBuilder: (context, index) {
          final item = display[index];

          if (item.isIncome) {
            final income = item.income!;
            final incomeCategories = ref.watch(incomeCategoriesProvider);
            final cat = getIncomeCategoryForSource(income.source, incomeCategories);
            return Dismissible(
              key: Key(income.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      l10n.deleteIncome,
                      style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                    ),
                    content: Text(
                      l10n.areYouSureDeleteIncome,
                      style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.delete),
                      ),
                    ],
                  ),
                ) ?? false;
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Theme.of(context).colorScheme.error,
                child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
              ),
              onDismissed: (_) {
                final deleted = income;
                final box = Hive.box<Income>('incomes');
                ref.read(incomesProvider.notifier).deleteIncome(income.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.incomeDeleted),
                    action: SnackBarAction(
                      label: l10n.undo,
                      onPressed: () {
                        box.put(deleted.id, deleted);
                      },
                    ),
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(cat.color).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(IconConstants.getIcon(cat.iconName), color: Color(cat.color), size: 22),
                ),
                title: Text(
                  income.note?.isNotEmpty == true ? income.note! : cat.name,
                  style: TextStyle(fontWeight: FontWeight.w500, color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  DateFormat('MMM d, yyyy').format(income.date),
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                trailing: Text(
                  '+${currency.symbol}${income.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4CAF50), fontSize: 16),
                ),
              ),
            );
          } else {
            final expense = item.expense!;
            Category category = categories.cast<Category>().firstWhere(
              (c) => c.id == expense.categoryId,
              orElse: () => Category(id: '', name: '', iconName: 'more_horiz', color: 0xFFB8B8B8),
            );
            final displayName = category.name.isEmpty ? l10n.unknown : category.name;

            return Dismissible(
              key: Key(expense.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      l10n.deleteExpense,
                      style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                    ),
                    content: Text(
                      l10n.areYouSureDeleteExpense,
                      style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.delete),
                      ),
                    ],
                  ),
                ) ?? false;
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Theme.of(context).colorScheme.error,
                child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
              ),
              onDismissed: (_) {
                final deleted = expense;
                final box = Hive.box<Expense>('expenses');
                ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.expenseDeleted),
                    action: SnackBarAction(
                      label: l10n.undo,
                      onPressed: () {
                        box.put(deleted.id, deleted);
                      },
                    ),
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(category.color).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(IconConstants.getIcon(category.iconName), color: Color(category.color), size: 22),
                ),
                title: Text(
                  expense.note?.isNotEmpty == true ? expense.note! : displayName,
                  style: TextStyle(fontWeight: FontWeight.w500, color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  DateFormat('MMM d, yyyy').format(expense.date),
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                trailing: Text(
                  '-${currency.symbol}${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFFF5252), fontSize: 16),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class _RecentItem {
  final DateTime date;
  final bool isIncome;
  final Expense? expense;
  final Income? income;

  _RecentItem.fromExpense(this.expense)
    : date = expense!.date,
      isIncome = false,
      income = null;

  _RecentItem.fromIncome(this.income)
    : date = income!.date,
      isIncome = true,
      expense = null;
}
