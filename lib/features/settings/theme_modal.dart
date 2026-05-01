import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/providers/theme_provider.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class ThemeModal extends ConsumerWidget {
  const ThemeModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final currentTheme = ref.watch(themeProvider);
    final isDarkMode = currentTheme == ThemeMode.dark;

    final surfaceColor = isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;
    final dividerColor = isDark ? AppTheme.darkDividerColor : AppTheme.dividerColor;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final backgroundColor = isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        top: 24,
        right: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.theme,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildThemeOption(
            context,
            ref,
            title: l10n.light,
            icon: Icons.light_mode_outlined,
            isSelected: !isDarkMode,
            textPrimary: textPrimary,
            backgroundColor: backgroundColor,
            dividerColor: dividerColor,
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            context,
            ref,
            title: l10n.dark,
            icon: Icons.dark_mode_outlined,
            isSelected: isDarkMode,
            textPrimary: textPrimary,
            backgroundColor: backgroundColor,
            dividerColor: dividerColor,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color textPrimary,
    required Color backgroundColor,
    required Color dividerColor,
  }) {
    return InkWell(
      onTap: () {
        ref.read(themeProvider.notifier).toggleTheme();
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? textPrimary.withAlpha(13) : backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? textPrimary : dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: textPrimary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: textPrimary,
                  fontSize: 16,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: textPrimary),
          ],
        ),
      ),
    );
  }
}