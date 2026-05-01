import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/core/providers/theme_provider.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class SummaryCard extends ConsumerWidget {
  final String title;
  final double? budget;

  const SummaryCard({super.key, required this.title, this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final monthlyExpense = ref.watch(monthlyTotalProvider);
    final monthlyIncome = ref.watch(monthlyIncomeTotalProvider);
    final balance = ref.watch(monthlyBalanceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCat = ref.watch(themeStyleProvider) == ThemeStyle.catTheme;

    final bgColor = (isCat && !isDark)
        ? Colors.white
        : (isCat && isDark)
            ? const Color(0xFF2B2426)  // soft pink-tinted dark
            : (isDark ? const Color(0xFF2D2D2D) : Colors.black);

    // On white cat-light card, flip text colors to dark
    final catLight = isCat && !isDark;
    final subtitleColor = catLight ? Colors.black54 : Colors.white70;
    final valueTextColor = catLight ? Colors.black87 : Colors.white;
    final dividerLineColor = catLight ? Colors.black12 : Colors.white24;
    final surplusColor = const Color(0xFF81C784);
    final deficitColor = const Color(0xFFEF9A9A);
    final incomeArrowColor = const Color(0xFF81C784);
    final expenseArrowColor = const Color(0xFFEF9A9A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Cat paw watermark (cat theme only)
          if (isCat)
            Positioned(
              right: -4,
              bottom: -4,
              child: Icon(Icons.pets, size: 72, color: AppTheme.catPrimary.withAlpha(45)),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isCat) const Text('🐱 ', style: TextStyle(fontSize: 14)),
                  Text(
                    title,
                    style: TextStyle(color: subtitleColor, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${currency.symbol}${balance.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: balance >= 0 ? surplusColor : deficitColor,
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
                        color: balance >= 0 ? surplusColor : deficitColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatColumn(
                      icon: Icons.arrow_downward_rounded,
                      iconColor: incomeArrowColor,
                      label: l10n.income,
                      value: '${currency.symbol}${monthlyIncome.toStringAsFixed(2)}',
                      labelColor: subtitleColor,
                      valueColor: valueTextColor,
                    ),
                  ),
                  Container(width: 1, height: 40, color: dividerLineColor),
                  Expanded(
                    child: _StatColumn(
                      icon: Icons.arrow_upward_rounded,
                      iconColor: expenseArrowColor,
                      label: l10n.expenses,
                      value: '${currency.symbol}${monthlyExpense.toStringAsFixed(2)}',
                      labelColor: subtitleColor,
                      valueColor: valueTextColor,
                    ),
                  ),
                ],
              ),
              if (budget != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (catLight ? Colors.black : Colors.white).withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.ofBudget('${currency.symbol}${budget!.toStringAsFixed(2)}'),
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
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
  final Color labelColor;
  final Color valueColor;

  const _StatColumn({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
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
            Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
