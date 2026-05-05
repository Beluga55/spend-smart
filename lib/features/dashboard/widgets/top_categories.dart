import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class TopCategoriesList extends ConsumerWidget {
  const TopCategoriesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final categories = ref.watch(expenseCategoriesProvider);
    final monthlyTotal = ref.watch(monthlyTotalProvider);

    final cs = Theme.of(context).colorScheme;
    final surfaceColor = cs.surface;
    final dividerColor = cs.outline;
    final textPrimary = cs.onSurface;
    final textSecondary = cs.onSurface.withAlpha(153);

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedEntries.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.topCategories,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  fontSize: 14,
                ),
              ),
              if (topCategories.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: textPrimary.withAlpha(13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${topCategories.length} ${l10n.categories.toLowerCase()}',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (topCategories.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 48,
                      color: textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noSpendingDataYet,
                      style: TextStyle(color: textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ...topCategories.map((entry) {
              final categoryId = entry.key;
              final spending = entry.value;
              final percentage = monthlyTotal > 0 ? (spending / monthlyTotal * 100) : 0.0;

              final category = categories.firstWhere(
                (c) => c.id == categoryId,
                orElse: () => Category(
                  id: categoryId,
                  name: l10n.unknown,
                  iconName: 'help_outline',
                  color: 0xFF999999,
                  isDefault: false,
                  categoryType: 'expense',
                ),
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
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: textSecondary.withAlpha(26),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(category.color),
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${currency.symbol}${spending.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
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
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
