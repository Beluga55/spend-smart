import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/providers/theme_provider.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class ThemeModal extends ConsumerWidget {
  const ThemeModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeState = ref.watch(themeStateProvider);
    final currentStyle = themeState.style;
    final currentMode = themeState.mode;

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
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
                decoration: BoxDecoration(color: dividerColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            // Cat ears when cat theme is active
            if (currentStyle == ThemeStyle.catTheme)
              Center(
                child: Text('🐱', style: TextStyle(fontSize: 36)),
              ),
            if (currentStyle == ThemeStyle.catTheme) const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.theme, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                IconButton(icon: Icon(Icons.close, color: textPrimary), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 24),
            _ThemeOption(
              label: l10n.light,
              icon: Icons.light_mode_outlined,
              swatch: AppTheme.backgroundColor,
              swatchBorder: AppTheme.dividerColor,
              isSelected: currentStyle == ThemeStyle.defaultTheme && currentMode == ThemeMode.light,
              textPrimary: textPrimary,
              backgroundColor: backgroundColor,
              dividerColor: dividerColor,
              onTap: () {
                ref.read(themeStateProvider.notifier).setTheme(ThemeStyle.defaultTheme, false);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _ThemeOption(
              label: l10n.dark,
              icon: Icons.dark_mode_outlined,
              swatch: AppTheme.darkBackgroundColor,
              swatchBorder: AppTheme.darkDividerColor,
              isSelected: currentStyle == ThemeStyle.defaultTheme && currentMode == ThemeMode.dark,
              textPrimary: textPrimary,
              backgroundColor: backgroundColor,
              dividerColor: dividerColor,
              onTap: () {
                ref.read(themeStateProvider.notifier).setTheme(ThemeStyle.defaultTheme, true);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _ThemeOption(
              label: l10n.catLight,
              icon: Icons.wb_sunny_outlined,
              swatch: AppTheme.catBackground,
              swatchBorder: AppTheme.catPrimary,
              isSelected: currentStyle == ThemeStyle.catTheme && currentMode == ThemeMode.light,
              textPrimary: textPrimary,
              backgroundColor: backgroundColor,
              dividerColor: dividerColor,
              onTap: () {
                ref.read(themeStateProvider.notifier).setTheme(ThemeStyle.catTheme, false);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _ThemeOption(
              label: l10n.catDark,
              icon: Icons.nightlight_outlined,
              swatch: AppTheme.catDarkBackground,
              swatchBorder: AppTheme.catDarkPrimary,
              isSelected: currentStyle == ThemeStyle.catTheme && currentMode == ThemeMode.dark,
              textPrimary: textPrimary,
              backgroundColor: backgroundColor,
              dividerColor: dividerColor,
              onTap: () {
                ref.read(themeStateProvider.notifier).setTheme(ThemeStyle.catTheme, true);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.swatch,
    required this.swatchBorder,
    required this.isSelected,
    required this.textPrimary,
    required this.backgroundColor,
    required this.dividerColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color swatch;
  final Color swatchBorder;
  final bool isSelected;
  final Color textPrimary;
  final Color backgroundColor;
  final Color dividerColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? textPrimary.withAlpha(13) : backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? textPrimary : dividerColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: textPrimary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: textPrimary, fontSize: 16),
              ),
            ),
            // Color swatch preview
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(color: swatchBorder, width: 2),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check, color: textPrimary),
            ],
          ],
        ),
      ),
    );
  }
}
