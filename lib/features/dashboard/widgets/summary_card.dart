import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class SummaryCard extends ConsumerWidget {
  final String title;
  final double? budget;

  const SummaryCard({super.key, required this.title, this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final monthlyExpense = ref.watch(monthlyTotalProvider);
    final monthlyIncome = ref.watch(monthlyIncomeTotalProvider);
    final balance = ref.watch(monthlyBalanceProvider);

    final bgColor = isDark ? const Color(0xFF2D2D2D) : AppTheme.primaryColor;
    const subtitleColor = Colors.white70;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: subtitleColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // Balance as the hero number
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${currency.symbol}${balance.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: balance >= 0
                      ? const Color(0xFF81C784)
                      : const Color(0xFFEF9A9A),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  balance >= 0 ? l10n.surplus : l10n.deficit,
                  style: TextStyle(
                    color: balance >= 0
                        ? const Color(0xFF81C784)
                        : const Color(0xFFEF9A9A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Income and Expense side by side
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  icon: Icons.arrow_downward_rounded,
                  iconColor: const Color(0xFF81C784),
                  label: l10n.income,
                  value:
                      '${currency.symbol}${monthlyIncome.toStringAsFixed(2)}',
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _StatColumn(
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFFEF9A9A),
                  label: l10n.expenses,
                  value:
                      '${currency.symbol}${monthlyExpense.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          if (budget != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.ofBudget(
                  '${currency.symbol}${budget!.toStringAsFixed(2)}',
                ),
                style: const TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatColumn({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
