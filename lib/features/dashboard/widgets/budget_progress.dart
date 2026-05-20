import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/constants/app_constants.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/core/providers/theme_provider.dart';
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

    final cs = Theme.of(context).colorScheme;
    final surfaceColor = cs.surface;
    final dividerColor = cs.outline;
    final textPrimary = cs.onSurface;
    final textSecondary = cs.onSurface.withAlpha(153);
    final semantic = Theme.of(context).extension<SemanticColors>();
    final successColor =
        semantic?.success ??
        (isDark ? const Color(0xFF81C784) : const Color(0xFF4CAF50));
    final warningColor =
        semantic?.warning ??
        (isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00));

    final criticalColor = isDark ? Colors.white : Colors.red;

    Color progressColor = successColor;
    if (isCritical) {
      progressColor = criticalColor;
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
                    color: isCritical ? criticalColor : textSecondary,
                  ),
                ),
                if (isWarning && !isCritical) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                _buildDailyAllowance(
                  currency,
                  dailyAllowance,
                  textPrimary,
                  textSecondary,
                  isCritical,
                  criticalColor,
                ),
                const SizedBox(height: 8),
                _buildProjectedSpending(
                  currency,
                  projected,
                  budgetAmount,
                  textPrimary,
                  textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAllowance(
    dynamic currency,
    double dailyAllowanceValue,
    Color textPrimary,
    Color textSecondary,
    bool isCritical,
    Color criticalColor,
  ) {
    if (dailyAllowanceValue <= 0) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(Icons.calendar_today, size: 14, color: textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'You can spend ${currency.symbol}${dailyAllowanceValue.toStringAsFixed(2)}/day',
            style: TextStyle(
              fontSize: 12,
              color: isCritical ? criticalColor.withAlpha(179) : textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectedSpending(
    dynamic currency,
    double projected,
    double budgetAmount,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (budgetAmount <= 0) return const SizedBox.shrink();

    // Cap projection at 10x budget to avoid absurd numbers from front-loaded spending
    final capped = projected.clamp(0, budgetAmount * 10);
    final diff = capped - budgetAmount;
    final isOverProjected = diff > 0;

    return Row(
      children: [
        Icon(Icons.insights, size: 14, color: textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            isOverProjected
                ? 'Projected: ${currency.symbol}${capped.toStringAsFixed(0)} (+${currency.symbol}${diff.toStringAsFixed(0)})'
                : 'Projected: ${currency.symbol}${capped.toStringAsFixed(0)} (-${currency.symbol}${(-diff).toStringAsFixed(0)})',
            style: TextStyle(fontSize: 12, color: textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
