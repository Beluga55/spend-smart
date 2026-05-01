import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/core/providers/theme_provider.dart';
import 'package:mobile_expense_tracker/core/providers/locale_provider.dart';
import 'package:mobile_expense_tracker/features/settings/currency_modal.dart';
import 'package:mobile_expense_tracker/features/settings/theme_modal.dart';
import 'package:mobile_expense_tracker/features/settings/language_modal.dart';
import 'package:mobile_expense_tracker/features/recurring/recurring_screen.dart';
import 'package:mobile_expense_tracker/features/summary/summary_screen.dart';
import 'package:mobile_expense_tracker/features/converter/converter_screen.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class DrawerContent extends ConsumerWidget {
  const DrawerContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final currentTheme = ref.watch(themeProvider);
    final isDarkMode = currentTheme == ThemeMode.dark;
    final themeStyle = ref.watch(themeStyleProvider);
    final isCat = themeStyle == ThemeStyle.catTheme;
    final themeLabel = isCat
        ? (isDarkMode ? l10n.catDark : l10n.catLight)
        : (isDarkMode ? l10n.dark : l10n.light);
    final themeIcon = isCat
        ? (isDarkMode ? Icons.nightlight_outlined : Icons.wb_sunny_outlined)
        : (isDarkMode ? Icons.dark_mode : Icons.light_mode);
    final currentLocale = ref.watch(localeProvider);
    final localeName = currentLocale.languageCode == 'zh' ? l10n.chinese : l10n.english;

    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);

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
              icon: Icons.attach_money,
              title: l10n.currency,
              trailing: Text(
                '${currency.symbol} ${currency.code}',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const CurrencyModal(),
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
              icon: Icons.language,
              title: l10n.language,
              trailing: Text(
                localeName,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const LanguageModal(),
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
              icon: themeIcon,
              title: l10n.theme,
              trailing: Text(
                themeLabel,
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const ThemeModal(),
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
              icon: Icons.repeat,
              title: l10n.recurringExpenses,
              trailing: const SizedBox(),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RecurringScreen()),
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
                  MaterialPageRoute(builder: (context) => const SummaryScreen()),
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
                  MaterialPageRoute(builder: (context) => const ConverterScreen()),
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
              child: Column(
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
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
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

