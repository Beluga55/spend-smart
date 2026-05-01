import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class SpendingTrendsChart extends ConsumerWidget {
  const SpendingTrendsChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final dailySpending = ref.watch(dailySpendingProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final currency = ref.watch(currencyProvider);

    final surfaceColor = isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;
    final dividerColor = isDark ? AppTheme.darkDividerColor : AppTheme.dividerColor;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final primaryColor = isDark ? Colors.white : AppTheme.primaryColor;

    if (dailySpending.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
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
      );
    }

    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final maxSpending = dailySpending.values.isEmpty
        ? 100.0
        : dailySpending.values.reduce((a, b) => a > b ? a : b);

    final maxY = (maxSpending * 1.3).clamp(10.0, double.infinity).toDouble();
    final yInterval = maxY / 4;
    final maxYAxisLabel = '${currency.symbol}${maxY.toInt()}';
    final leftTitleReservedSize = (maxYAxisLabel.length * 8.0).clamp(44.0, 76.0).toDouble();

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
                l10n.dailySpending,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: textPrimary.withAlpha(13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${l10n.max} ${currency.symbol}${maxSpending.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final rodWidth = (constraints.maxWidth / daysInMonth * 0.55).clamp(4.0, 12.0).toDouble();
                final barGroups = <BarChartGroupData>[];

                for (int day = 1; day <= daysInMonth; day++) {
                  final date = DateTime(selectedMonth.year, selectedMonth.month, day);
                  final spending = dailySpending[date] ?? 0.0;
                  barGroups.add(
                    BarChartGroupData(
                      x: day,
                      barRods: [
                        BarChartRodData(
                          fromY: 0,
                          toY: spending,
                          color: primaryColor,
                          width: rodWidth,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                  );
                }

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceBetween,
                    minY: 0,
                    baselineY: 0,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => isDark ? Colors.white : Colors.black,
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            'Day ${group.x}\n${currency.symbol}${rod.toY.toStringAsFixed(2)}',
                            TextStyle(
                              color: isDark ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final day = value.toInt();
                            if (day == 1 || day == 15 || day == daysInMonth) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: leftTitleReservedSize,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            return SizedBox(
                              width: leftTitleReservedSize - 4,
                              child: Text(
                                '${currency.symbol}${value.toInt()}',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: dividerColor,
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
