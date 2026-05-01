import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class CategoryChart extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final List<Category> categories;

  const CategoryChart({
    super.key,
    required this.categoryTotals,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final cs = Theme.of(context).colorScheme;
    final surfaceColor = cs.surface;
    final dividerColor = cs.outline;
    final textSecondary = cs.onSurface.withAlpha(153);

    if (categoryTotals.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor),
        ),
        child: Center(
          child: Text(
            l10n.noExpensesYet,
            style: TextStyle(color: textSecondary),
          ),
        ),
      );
    }

    final total = categoryTotals.values.fold(0.0, (sum, v) => sum + v);
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = sortedEntries.map((entry) {
      Category category = categories.cast<Category>().firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Category(id: '', name: 'Unknown', iconName: 'more_horiz', color: 0xFFB8B8B8),
      );
      final percentage = (entry.value / total * 100);

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        color: Color(category.color),
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: sortedEntries.map((entry) {
              Category category = categories.cast<Category>().firstWhere(
                (c) => c.id == entry.key,
                orElse: () => Category(id: '', name: 'Unknown', iconName: 'more_horiz', color: 0xFFB8B8B8),
              );
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(category.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
