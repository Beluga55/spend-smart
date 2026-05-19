import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mobile_expense_tracker/features/recurring/recurring_screen.dart';
import 'package:mobile_expense_tracker/features/summary/summary_screen.dart';
import 'package:mobile_expense_tracker/features/saving_goals/saving_goals_screen.dart';
import 'package:mobile_expense_tracker/features/converter/converter_screen.dart';
import 'package:mobile_expense_tracker/features/categories/categories_screen.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class DrawerContent extends ConsumerWidget {
  const DrawerContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(
      context,
    ).colorScheme.onSurface.withAlpha(153);

    return Drawer(
      backgroundColor: surfaceColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                l10n.appTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),
            Divider(color: dividerColor, height: 1),
            const SizedBox(height: 16),
            _buildDrawerItem(
              context: context,
              icon: Icons.repeat,
              title: l10n.recurringExpenses,
              trailing: const SizedBox(),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecurringScreen(),
                  ),
                );
              },
              textPrimary: textPrimary,
              surfaceColor: surfaceColor,
              backgroundColor: backgroundColor,
              dividerColor: dividerColor,
            ),
            const SizedBox(height: 8),
            _buildDrawerItem(
              context: context,
              icon: Icons.analytics_outlined,
              title: l10n.monthlySummary,
              trailing: const SizedBox(),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SummaryScreen(),
                  ),
                );
              },
              textPrimary: textPrimary,
              surfaceColor: surfaceColor,
              backgroundColor: backgroundColor,
              dividerColor: dividerColor,
            ),
            const SizedBox(height: 8),
            _buildDrawerItem(
              context: context,
              icon: Icons.savings_outlined,
              title: l10n.savingGoals,
              trailing: const SizedBox(),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavingGoalsScreen(),
                  ),
                );
              },
              textPrimary: textPrimary,
              surfaceColor: surfaceColor,
              backgroundColor: backgroundColor,
              dividerColor: dividerColor,
            ),
            const SizedBox(height: 8),
            _buildDrawerItem(
              context: context,
              icon: Icons.currency_exchange,
              title: l10n.currencyConverter,
              trailing: const SizedBox(),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConverterScreen(),
                  ),
                );
              },
              textPrimary: textPrimary,
              surfaceColor: surfaceColor,
              backgroundColor: backgroundColor,
              dividerColor: dividerColor,
            ),
            const SizedBox(height: 8),
            _buildDrawerItem(
              context: context,
              icon: Icons.category_outlined,
              title: l10n.categories,
              trailing: const SizedBox(),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoriesScreen(),
                  ),
                );
              },
              textPrimary: textPrimary,
              surfaceColor: surfaceColor,
              backgroundColor: backgroundColor,
              dividerColor: dividerColor,
            ),
            const SizedBox(height: 16),
            Divider(color: dividerColor, height: 1),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '';
                  final build = snapshot.data?.buildNumber ?? '';
                  final versionStr = version.isNotEmpty
                      ? 'v$version+$build'
                      : '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.about,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.developedBy,
                        style: TextStyle(fontSize: 14, color: textSecondary),
                      ),
                      if (versionStr.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          versionStr,
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color surfaceColor,
    required Color backgroundColor,
    required Color dividerColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: textPrimary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ),
              trailing,
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: textPrimary.withAlpha(128),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
