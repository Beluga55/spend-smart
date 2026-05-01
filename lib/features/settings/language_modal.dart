import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/providers/locale_provider.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class LanguageModal extends ConsumerWidget {
  const LanguageModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final textPrimary = Theme.of(context).colorScheme.onSurface;

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
                l10n.language,
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
          _buildLanguageOption(
            context,
            ref,
            locale: const Locale('en'),
            title: l10n.english,
            isSelected: currentLocale.languageCode == 'en',
          ),
          const SizedBox(height: 12),
          _buildLanguageOption(
            context,
            ref,
            locale: const Locale('zh'),
            title: l10n.chinese,
            isSelected: currentLocale.languageCode == 'zh',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref, {
    required Locale locale,
    required String title,
    required bool isSelected,
  }) {
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = Theme.of(context).colorScheme.outline;

    return InkWell(
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(locale.languageCode);
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
              Icon(
                Icons.check,
                color: textPrimary,
              ),
          ],
        ),
      ),
    );
  }
}


