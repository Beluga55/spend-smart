import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/core/models/recurring_expense.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/features/recurring/widgets/recurring_modal.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recurringExpenses = ref.watch(recurringExpensesProvider);
    final categories = ref.watch(categoriesProvider);
    final currency = ref.watch(currencyProvider);

    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = Theme.of(context).colorScheme.outline;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurringExpenses),
      ),
      body: recurringExpenses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.repeat,
                    size: 64,
                    color: textSecondary.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noRecurringExpensesYet,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tapToAddFirstRecurring,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recurringExpenses.length,
              itemBuilder: (context, index) {
                final recurring = recurringExpenses[index];
                Category? category;
                try {
                  category = categories.firstWhere((c) => c.id == recurring.categoryId);
                } catch (_) {
                  category = Category(id: '', name: 'Unknown', iconName: 'category', color: 0xFFB8B8B8);
                }
                return _buildRecurringCard(
                  context,
                  ref,
                  recurring,
                  category,
                  currency.symbol,
                  l10n,
                  textPrimary,
                  textSecondary,
                  surfaceColor,
                  backgroundColor,
                  dividerColor,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'recurring_fab',
        onPressed: () => _showAddRecurringModal(context, ref, l10n),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRecurringCard(
    BuildContext context,
    WidgetRef ref,
    RecurringExpense recurring,
    Category category,
    String currencySymbol,
    AppLocalizations l10n,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
    Color backgroundColor,
    Color dividerColor,
  ) {
    final isActive = recurring.isActive;

    return GestureDetector(
      onTap: () => _showEditRecurringModal(context, ref, recurring, l10n),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(category.color).withAlpha(isActive ? 25 : 13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    IconConstants.getIcon(category.iconName),
                    color: Color(category.color).withAlpha(isActive ? 255 : 128),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recurring.note?.isNotEmpty == true ? recurring.note! : category.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: isActive ? textPrimary : textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildFrequencyBadge(recurring.frequency, textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currencySymbol${recurring.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: isActive ? textPrimary : textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.successColor.withAlpha(25) : textSecondary.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Paused',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isActive ? AppTheme.successColor : textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (recurring.lastCreated != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 14,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Last: ${_formatDate(recurring.lastCreated!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Next: ${_getNextDueDate(recurring)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyBadge(RecurringFrequency frequency, Color textSecondary) {
    String label;
    switch (frequency) {
      case RecurringFrequency.daily:
        label = 'Daily';
        break;
      case RecurringFrequency.weekly:
        label = 'Weekly';
        break;
      case RecurringFrequency.monthly:
        label = 'Monthly';
        break;
      case RecurringFrequency.yearly:
        label = 'Yearly';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: textSecondary.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _getNextDueDate(RecurringExpense recurring) {
    final next = recurring.getNextDueDate();
    if (next == null) return 'No future';
    return _formatDate(next);
  }

  void _showAddRecurringModal(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecurringModal(
        onSave: (amount, categoryId, frequency, startDate, note, endDate) {
          ref.read(recurringExpensesProvider.notifier).addRecurring(
            amount: amount,
            categoryId: categoryId,
            frequency: frequency,
            startDate: startDate,
            note: note,
            endDate: endDate,
          );
        },
      ),
    );
  }

  void _showEditRecurringModal(BuildContext context, WidgetRef ref, RecurringExpense recurring, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecurringModal(
        recurring: recurring,
        onSave: (amount, categoryId, frequency, startDate, note, endDate) {
          ref.read(recurringExpensesProvider.notifier).updateRecurring(
            recurring.copyWith(
              amount: amount,
              categoryId: categoryId,
              frequency: frequency,
              startDate: startDate,
              note: note,
              endDate: endDate,
            ),
          );
        },
        onToggleActive: () {
          ref.read(recurringExpensesProvider.notifier).toggleActive(recurring.id);
        },
        onDelete: () {
          ref.read(recurringExpensesProvider.notifier).deleteRecurring(recurring.id);
        },
      ),
    );
  }
}
