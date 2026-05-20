import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

enum QuickAddAction { expense, income }

class QuickAddSheet extends StatelessWidget {
  final void Function(QuickAddAction action) onAction;

  const QuickAddSheet({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final semantic = Theme.of(context).extension<SemanticColors>();

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _QuickAddTile(
                  icon: Icons.arrow_upward_rounded,
                  label: l10n.addExpense,
                  color: const Color(0xFFFF5252),
                  textPrimary: textPrimary,
                  dividerColor: dividerColor,
                  onTap: () {
                    Navigator.pop(context);
                    onAction(QuickAddAction.expense);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAddTile(
                  icon: Icons.arrow_downward_rounded,
                  label: l10n.addIncome,
                  color: const Color(0xFF4CAF50),
                  textPrimary: textPrimary,
                  dividerColor: dividerColor,
                  onTap: () {
                    Navigator.pop(context);
                    onAction(QuickAddAction.income);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAddTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textPrimary;
  final Color dividerColor;
  final VoidCallback onTap;

  const _QuickAddTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.textPrimary,
    required this.dividerColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


