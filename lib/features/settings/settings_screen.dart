import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/core/providers/theme_provider.dart';
import 'package:mobile_expense_tracker/core/providers/locale_provider.dart';
import 'package:mobile_expense_tracker/core/providers/backup_provider.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:mobile_expense_tracker/core/services/sync_status_provider.dart';
import 'package:mobile_expense_tracker/core/services/recurring_sync_service.dart';
import 'package:mobile_expense_tracker/features/settings/currency_modal.dart';
import 'package:mobile_expense_tracker/features/settings/theme_modal.dart';
import 'package:mobile_expense_tracker/features/settings/language_modal.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await SupabaseService.refreshSession();
      if (mounted) {
        ref.invalidate(authStateProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final currentTheme = ref.watch(themeProvider);
    final isDarkMode = currentTheme == ThemeMode.dark;
    final currentLocale = ref.watch(localeProvider);
    final localeName = currentLocale.languageCode == 'zh'
        ? l10n.chinese
        : l10n.english;
    final autoBackup = ref.watch(autoBackupProvider);
    final syncState = ref.watch(syncNotifierProvider);
    final authState = ref.watch(authStateProvider);

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);

    final isAnonymous = authState.maybeWhen(
      data: (state) => state.isAnonymous,
      orElse: () => true,
    );

    final linkedEmail = authState.maybeWhen(
      data: (state) => state.user?.email,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(l10n.account, textSecondary),
          if (!isAnonymous) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          linkedEmail ?? 'Email linked',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cloud backup connected',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.link_off,
              title: l10n.unlinkGoogle,
              subtitle: linkedEmail,
              textPrimary: textPrimary,
              backgroundColor: backgroundColor,
              dividerColor: dividerColor,
              onTap: () => _unlinkGoogle(context, ref, l10n),
            ),
          ],
          if (isAnonymous) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () => _signInWithGoogle(context, ref, l10n),
                icon: const Icon(Icons.account_circle, size: 20),
                label: Text(l10n.signInWithGoogle),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildSectionHeader(l10n.backup, textSecondary),
          _buildSettingsTile(
            context: context,
            icon: Icons.cloud_upload_outlined,
            title: l10n.backupNow,
            subtitle: 'Upload to cloud',
            textPrimary: textPrimary,
            backgroundColor: backgroundColor,
            dividerColor: dividerColor,
            onTap: () => _backupNow(context, ref, l10n),
          ),
          _buildSwitchTile(
            icon: Icons.cloud_sync_outlined,
            title: l10n.autoBackup,
            subtitle: autoBackup ? 'Daily when online' : 'Off',
            value: autoBackup,
            textPrimary: textPrimary,
            backgroundColor: backgroundColor,
            dividerColor: dividerColor,
            onChanged: (value) {
              ref.read(autoBackupProvider.notifier).state = value;
            },
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.cloud_download_outlined,
            title: l10n.restoreFromCloud,
            subtitle: 'Download from cloud',
            textPrimary: textPrimary,
            backgroundColor: backgroundColor,
            dividerColor: dividerColor,
            onTap: () => _restoreFromCloud(context, ref, l10n),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(l10n.preferences, textSecondary),
          _buildSettingsTile(
            context: context,
            icon: Icons.attach_money,
            title: l10n.currency,
            trailing: Text(
              '${currency.symbol} ${currency.code}',
              style: TextStyle(color: textSecondary),
            ),
            textPrimary: textPrimary,
            backgroundColor: backgroundColor,
            dividerColor: dividerColor,
            onTap: () => _showCurrencyModal(context),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.language,
            title: l10n.language,
            trailing: Text(localeName, style: TextStyle(color: textSecondary)),
            textPrimary: textPrimary,
            backgroundColor: backgroundColor,
            dividerColor: dividerColor,
            onTap: () => _showLanguageModal(context),
          ),
          _buildSettingsTile(
            context: context,
            icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
            title: l10n.theme,
            trailing: Text(
              isDarkMode ? l10n.dark : l10n.light,
              style: TextStyle(color: textSecondary),
            ),
            textPrimary: textPrimary,
            backgroundColor: backgroundColor,
            dividerColor: dividerColor,
            onTap: () => _showThemeModal(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required Color textPrimary,
    required Color backgroundColor,
    required Color dividerColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: textPrimary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: textPrimary.withAlpha(153),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
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
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Color textPrimary,
    required Color backgroundColor,
    required Color dividerColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: textPrimary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: textPrimary.withAlpha(153),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }

  void _backupNow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    try {
      final backupService = ref.read(backupServiceProvider);
      await backupService.uploadToCloud();
      ref.read(syncNotifierProvider.notifier).setSynced();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.backupSuccess)));
      }
    } catch (e) {
      ref.read(syncNotifierProvider.notifier).setError(e.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.backupError}: $e')));
      }
    }
  }

  void _restoreFromCloud(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    // Show loading while fetching cloud backup info
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    BackupData? cloudBackup;
    BackupData? localData;
    try {
      final backupService = ref.read(backupServiceProvider);
      cloudBackup = await backupService.downloadFromCloud();
      localData = await backupService.gatherData();
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // dismiss loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.restoreError}: $e')));
      }
      return;
    }

    if (!context.mounted) return;
    Navigator.pop(context); // dismiss loading

    if (cloudBackup == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noBackupFound)));
      return;
    }

    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restore),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.restoreCompareMessage,
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDataColumn(
                      title: l10n.localData,
                      icon: Icons.phone_android,
                      color: Colors.blue,
                      data: localData!,
                      l10n: l10n,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDataColumn(
                      title: l10n.cloudBackup,
                      icon: Icons.cloud,
                      color: Colors.green,
                      data: cloudBackup!,
                      l10n: l10n,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.restoreConfirm,
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.restore),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final backupService = ref.read(backupServiceProvider);
        await backupService.restoreFromCloud();
        ref.read(syncNotifierProvider.notifier).setSynced();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.restoreSuccess)));
        }
      } catch (e) {
        ref.read(syncNotifierProvider.notifier).setError(e.toString());
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${l10n.restoreError}: $e')));
        }
      }
    }
  }

  Widget _buildDataColumn({
    required String title,
    required IconData icon,
    required Color color,
    required BackupData data,
    required AppLocalizations l10n,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final dateStr =
        '${data.exportedAt.day}/${data.exportedAt.month}/${data.exportedAt.year}';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildCountRow(
            l10n.expenses,
            data.expenses.length,
            textPrimary,
            textSecondary,
          ),
          _buildCountRow(
            l10n.categories,
            data.categories.length,
            textPrimary,
            textSecondary,
          ),
          _buildCountRow(
            l10n.savingGoals,
            data.savingGoals.length,
            textPrimary,
            textSecondary,
          ),
          _buildCountRow(
            l10n.recurringExpenses,
            data.recurringExpenses.length,
            textPrimary,
            textSecondary,
          ),
          const SizedBox(height: 6),
          Text(dateStr, style: TextStyle(fontSize: 10, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCountRow(
    String label,
    int count,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CurrencyModal(),
    );
  }

  void _showLanguageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const LanguageModal(),
    );
  }

  void _showThemeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ThemeModal(),
    );
  }

  void _signInWithGoogle(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    try {
      await SupabaseService.signInWithGoogle();
      // The auth state will update automatically via the stream provider
      // when the OAuth callback completes
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.googleSignInError}: $e')),
        );
      }
    }
  }

  void _unlinkGoogle(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.unlinkGoogle),
          content: Text(
            l10n.unlinkGoogleConfirm,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.unlinkGoogle),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await SupabaseService.unlinkGoogle();
        ref.invalidate(authStateProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.unlinkSuccess)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${l10n.unlinkError}: $e')));
        }
      }
    }
  }
}




