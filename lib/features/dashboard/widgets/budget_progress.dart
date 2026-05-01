import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/constants/app_constants.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class BudgetProgressCard extends ConsumerWidget {
  final double progress;
  final double budgetAmount;
  final double currentAmount;

  const BudgetProgressCard({
    super.key,
    required this.progress,
    required this.budgetAmount,
    required this.currentAmount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final remaining = budgetAmount - currentAmount;
    final isWarning = progress >= AppConstants.budgetWarningThreshold;
    final isCritical = progress >= AppConstants.budgetCriticalThreshold;
    final dailyAllowance = ref.watch(dailyAllowanceProvider);
    final projected = ref.watch(projectedSpendingProvider);

    final surfaceColor = isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;
    final dividerColor = isDark ? AppTheme.darkDividerColor : AppTheme.dividerColor;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final successColor = isDark ? AppTheme.darkSuccessColor : AppTheme.successColor;
    final warningColor = isDark ? AppTheme.darkWarningColor : AppTheme.warningColor;

    Color progressColor = successColor;
    if (isCritical) {
      progressColor = Colors.white;
    } else if (isWarning) {
      progressColor = warningColor;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: progress / 100,
                    strokeWidth: 8,
                    backgroundColor: dividerColor,
                    valueColor: AlwaysStoppedAnimation(progressColor),
                  ),
                ),
                Text(
                  '${progress.toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.budgetStatus,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCritical
                    ? l10n.overBudget
                    : remaining >= 0
                      ? '${currency.symbol}${remaining.toStringAsFixed(2)} ${l10n.remaining}'
                      : '${currency.symbol}${(-remaining).toStringAsFixed(2)} ${l10n.overBudget}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isCritical ? Colors.white : textSecondary,
                  ),
                ),
                if (isWarning && !isCritical) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: textSecondary.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.approachingLimit,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _buildDailyAllowance(currency, dailyAllowance, textPrimary, textSecondary, isCritical),
                const SizedBox(height: 8),
                _buildProjectedSpending(currency, projected, budgetAmount, textPrimary, textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAllowance(dynamic currency, double dailyAllowanceValue, Color textPrimary, Color textSecondary, bool isCritical) {
    if (dailyAllowanceValue <= 0) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 14,
          color: textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          'You can spend ${currency.symbol}${dailyAllowanceValue.toStringAsFixed(2)}/day',
          style: TextStyle(
            fontSize: 12,
            color: isCritical ? Colors.white.withAlpha(179) : textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectedSpending(dynamic currency, double projected, double budgetAmount, Color textPrimary, Color textSecondary) {
    if (budgetAmount <= 0) return const SizedBox.shrink();

    final diff = projected - budgetAmount;
    final isOverProjected = diff > 0;

    return Row(
      children: [
        Icon(
          Icons.insights,
          size: 14,
          color: textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          isOverProjected
            ? 'Projected: ${currency.symbol}${projected.toStringAsFixed(0)} (+${currency.symbol}${diff.toStringAsFixed(0)})'
            : 'Projected: ${currency.symbol}${projected.toStringAsFixed(0)} (-${currency.symbol}${(-diff).toStringAsFixed(0)})',
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}