import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/core/providers/theme_provider.dart';
import 'package:mobile_expense_tracker/core/providers/locale_provider.dart';
import 'package:mobile_expense_tracker/core/providers/font_provider.dart';
import 'package:mobile_expense_tracker/core/providers/backup_provider.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:mobile_expense_tracker/core/services/notification_service.dart';
import 'package:mobile_expense_tracker/core/services/biometric_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/services/sync_status_provider.dart';
import 'package:mobile_expense_tracker/core/providers/update_provider.dart';
import 'package:mobile_expense_tracker/core/providers/ai_provider.dart';

import 'package:mobile_expense_tracker/features/settings/currency_modal.dart';
import 'package:mobile_expense_tracker/features/settings/theme_modal.dart';
import 'package:mobile_expense_tracker/features/settings/language_modal.dart';
import 'package:mobile_expense_tracker/features/settings/ai_settings_modal.dart';
import 'package:mobile_expense_tracker/features/feedback/feedback_modal.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final themeState = ref.watch(themeStateProvider);
    final currentStyle = themeState.style;
    final currentMode = themeState.mode;
    final isDarkMode = currentMode == ThemeMode.dark;

    String themeName = '';
    if (currentStyle == ThemeStyle.defaultTheme) {
      themeName = isDarkMode ? l10n.dark : l10n.light;
    } else if (currentStyle == ThemeStyle.catTheme) {
      themeName = isDarkMode ? l10n.catDark : l10n.catLight;
    } else if (currentStyle == ThemeStyle.limeTheme) {
      themeName = isDarkMode ? l10n.limeDark : l10n.limeLight;
    }
    final currentLocale = ref.watch(localeProvider);
    final localeName = currentLocale.languageCode == 'zh'
        ? l10n.chinese
        : l10n.english;
    final fontFamily = ref.watch(fontFamilyProvider);
    final autoBackup = ref.watch(autoBackupProvider);
    final authState = ref.watch(authStateProvider);

    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(
      context,
    ).colorScheme.onSurface.withAlpha(153);
    final semantic = Theme.of(context).extension<SemanticColors>();

    final isAnonymous = authState.maybeWhen(
      data: (state) {
        final settingsBox = Hive.box('settings');
        final hiveLinked =
            settingsBox.get('googleLinked', defaultValue: false) as bool;
        // Trust Hive as source of truth - ignore Supabase session state
        return !hiveLinked;
      },
      orElse: () => true,
    );

    final linkedEmail = authState.maybeWhen(
      data: (state) {
        final settingsBox = Hive.box('settings');
        return settingsBox.get('googleEmail') as String?;
      },
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
            GestureDetector(
              onLongPress: () => _resetAuthState(context, ref),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
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
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
              themeName,
              style: TextStyle(color: textSecondary),
            ),
            textPrimary: textPrimary,
            backgroundColor: backgroundColor,
            dividerColor: dividerColor,
            onTap: () => _showThemeModal(context),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.text_fields,
            title: l10n.font,
            trailing: Text(
              fontFamily == FontFamily.fredoka
                  ? l10n.fredokaCat
                  : fontFamily == FontFamily.comfortaa
                      ? l10n.comfortaa
                      : l10n.soraDefault,
              style: TextStyle(color: textSecondary),
            ),
            textPrimary: textPrimary,
            backgroundColor: backgroundColor,
            dividerColor: dividerColor,
            onTap: () => _showFontModal(context),
          ),
          Builder(
            builder: (context) {
              final showStreak =
                  Hive.box(
                        'settings',
                      ).get('showStreakBanner', defaultValue: true)
                      as bool;
              return _buildSwitchTile(
                icon: Icons.local_fire_department_outlined,
                title: l10n.showStreakBanner,
                subtitle: l10n.showStreakBannerSubtitle,
                value: showStreak,
                textPrimary: textPrimary,
                backgroundColor: backgroundColor,
                dividerColor: dividerColor,
                onChanged: (val) {
                  Hive.box('settings').put('showStreakBanner', val);
                  setState(() {});
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(l10n.notifications, textSecondary),
          Builder(
            builder: (context) {
              final settingsBox = Hive.box('settings');
              final reminderEnabled =
                  settingsBox.get('reminderEnabled', defaultValue: true)
                      as bool;
              final reminderHour =
                  settingsBox.get('reminderHour', defaultValue: 20) as int;
              final reminderMinute =
                  settingsBox.get('reminderMinute', defaultValue: 0) as int;
              final timeDisplay = TimeOfDay(
                hour: reminderHour,
                minute: reminderMinute,
              ).format(context);
              return Column(
                children: [
                  _buildSwitchTile(
                    icon: reminderEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off_outlined,
                    title: l10n.dailyReminder,
                    subtitle: reminderEnabled
                        ? l10n.reminderEveryDayAt(timeDisplay)
                        : l10n.reminderDisabled,
                    value: reminderEnabled,
                    textPrimary: textPrimary,
                    backgroundColor: backgroundColor,
                    dividerColor: dividerColor,
                    onChanged: (val) async {
                      if (val) {
                        await NotificationService.scheduleDailyReminder(
                          TimeOfDay(hour: reminderHour, minute: reminderMinute),
                        );
                      } else {
                        await NotificationService.cancelReminder();
                      }
                      setState(() {});
                    },
                  ),
                  if (reminderEnabled)
                    _buildSettingsTile(
                      context: context,
                      icon: Icons.access_time,
                      title: l10n.reminderTime,
                      trailing: Text(
                        timeDisplay,
                        style: TextStyle(color: textSecondary),
                      ),
                      textPrimary: textPrimary,
                      backgroundColor: backgroundColor,
                      dividerColor: dividerColor,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: reminderHour,
                            minute: reminderMinute,
                          ),
                        );
                        if (picked != null) {
                          await NotificationService.scheduleDailyReminder(
                            picked,
                          );
                          setState(() {});
                        }
                      },
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(l10n.security, textSecondary),
          Builder(
            builder: (context) {
              final biometricEnabled = BiometricService.isEnabled();
              return _buildSwitchTile(
                icon: biometricEnabled ? Icons.lock : Icons.lock_open,
                title: l10n.appLock,
                subtitle: biometricEnabled
                    ? l10n.appLockSubtitle
                    : l10n.reminderDisabled,
                value: biometricEnabled,
                textPrimary: textPrimary,
                backgroundColor: backgroundColor,
                dividerColor: dividerColor,
                onChanged: (val) async {
                  if (val) {
                    final supported =
                        await BiometricService.isDeviceSupported();
                    final canCheck =
                        await BiometricService.canCheckBiometrics();
                    if (!supported || !canCheck) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.biometricNotAvailable)),
                        );
                      }
                      return;
                    }
                    final authenticated = await BiometricService.authenticate(
                      localizedReason: l10n.biometricReason,
                    );
                    if (authenticated) {
                      await BiometricService.setEnabled(true);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.biometricSetupSuccess)),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.biometricSetupFailed)),
                        );
                      }
                    }
                  } else {
                    await BiometricService.setEnabled(false);
                  }
                  setState(() {});
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('AI Assistant', textSecondary),
          _buildSettingsTile(
            context: context,
            icon: Icons.auto_awesome,
            title: 'AI Settings',
            subtitle: ref.watch(aiSettingsProvider).hasAnyKey
                ? 'Tap to manage features'
                : 'Get AI-powered receipt scanning & insights',
            textPrimary: textPrimary,
            backgroundColor: backgroundColor,
            dividerColor: dividerColor,
            onTap: () => _showAISettingsModal(context),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(l10n.feedback, textSecondary),
          _buildSettingsTile(
            context: context,
            icon: Icons.feedback_outlined,
            title: l10n.sendFeedback,
            subtitle: 'Help us improve the app',
            textPrimary: textPrimary,
            backgroundColor: backgroundColor,
            dividerColor: dividerColor,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const FeedbackModal(),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('About', textSecondary),
          _buildUpdateTile(
            context,
            textPrimary,
            backgroundColor,
            dividerColor,
            textSecondary,
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
    final textSecondary = Theme.of(
      context,
    ).colorScheme.onSurface.withAlpha(153);

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
          _buildCountRow(
            l10n.wallets,
            data.wallets.length,
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
      useSafeArea: true,
      builder: (context) => const ThemeModal(),
    );
  }

  void _showAISettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AISettingsModal(),
    );
  }

  void _showFontModal(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final fontFamily = ref.watch(fontFamilyProvider);
          final mq = MediaQuery.of(ctx);
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + mq.viewInsets.bottom + mq.padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.font,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(l10n.soraDefault),
                  trailing: fontFamily == FontFamily.sora
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    ref
                        .read(fontFamilyProvider.notifier)
                        .setFont(FontFamily.sora);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: Text(l10n.fredokaCat),
                  trailing: fontFamily == FontFamily.fredoka
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    ref
                        .read(fontFamilyProvider.notifier)
                        .setFont(FontFamily.fredoka);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: Text(l10n.comfortaa),
                  trailing: fontFamily == FontFamily.comfortaa
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    ref
                        .read(fontFamilyProvider.notifier)
                        .setFont(FontFamily.comfortaa);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _signInWithGoogle(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    try {
      final response = await SupabaseService.signInWithGoogle();
      // Save linked state to Hive (reliable, survives any Supabase session bugs)
      final settingsBox = Hive.box('settings');
      await settingsBox.put('googleLinked', true);
      await settingsBox.put('googleEmail', response.user?.email);
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
        // Clear our own auth state flag (this is what the UI reads)
        final settingsBox = Hive.box('settings');
        await settingsBox.delete('googleLinked');
        await settingsBox.delete('googleEmail');
        await SupabaseService.unlinkGoogle();
        ref.invalidate(authStateProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.unlinkSuccess)));
        }
      } catch (e) {
        // Even if Supabase fails, the Hive flags are already cleared
        // so the UI will show the correct unlinked state
        ref.invalidate(authStateProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.unlinkSuccess)));
        }
      }
    }
  }

  void _resetAuthState(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Account State'),
        content: const Text(
          'This will clear your login session and restart the app. '
          'Your expenses and data will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset & Restart'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final settingsBox = Hive.box('settings');
        await settingsBox.delete('googleLinked');
        await settingsBox.delete('googleEmail');
        await SupabaseService.forceRefreshAuth();
      } catch (_) {}
      ref.invalidate(authStateProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Account state reset')));
      }
    }
  }

  Widget _buildUpdateTile(
    BuildContext context,
    Color textPrimary,
    Color backgroundColor,
    Color dividerColor,
    Color textSecondary,
  ) {
    final updateState = ref.watch(updateProvider);
    final l10n = AppLocalizations.of(context)!;

    String statusText;
    Widget? trailing;

    switch (updateState.status) {
      case UpdateStatus.checking:
        statusText = 'Checking…';
        trailing = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        break;
      case UpdateStatus.available:
        final version = updateState.latestUpdate?.version ?? '';
        statusText = l10n.newVersionAvailable(version);
        trailing = Text(
          l10n.installUpdate,
          style: TextStyle(color: textSecondary),
        );
        break;
      case UpdateStatus.downloading:
        final progress = updateState.progress;
        statusText = l10n.downloadingUpdate;
        trailing = Text(
          '${(progress * 100).toStringAsFixed(0)}%',
          style: TextStyle(color: textSecondary),
        );
        break;
      case UpdateStatus.ready:
        statusText = 'Ready to install';
        trailing = Text(
          l10n.installUpdate,
          style: TextStyle(color: textSecondary),
        );
        break;
      case UpdateStatus.upToDate:
        statusText = l10n.upToDate;
        break;
      default:
        statusText = l10n.checkForUpdates;
        break;
    }

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '';
        final build = snapshot.data?.buildNumber ?? '';
        final versionLabel = version.isNotEmpty ? 'v$version+$build' : '';
        final subtitle = versionLabel.isNotEmpty
            ? '$statusText · Current: $versionLabel'
            : statusText;

        return _buildSettingsTile(
          context: context,
          icon: Icons.system_update,
          title: l10n.checkForUpdates,
          trailing: trailing,
          textPrimary: textPrimary,
          backgroundColor: backgroundColor,
          dividerColor: dividerColor,
          subtitle: subtitle,
          onTap: () => _handleUpdateTap(context),
        );
      },
    );
  }

  void _handleUpdateTap(BuildContext context) async {
    final notifier = ref.read(updateProvider.notifier);
    final state = ref.read(updateProvider);

    if (state.status == UpdateStatus.available) {
      _showUpdateDownloadDialog(context);
    } else if (state.status == UpdateStatus.ready) {
      _installApk(state.apkPath!);
    } else if (state.status != UpdateStatus.checking &&
        state.status != UpdateStatus.downloading) {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion =
          '${packageInfo.version}+${packageInfo.buildNumber}';
      await notifier.checkForUpdate(currentVersion);

      final newState = ref.read(updateProvider);
      if (newState.status == UpdateStatus.available) {
        _showUpdateDownloadDialog(context);
      } else if (newState.status == UpdateStatus.upToDate && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.upToDate)),
        );
      }
    }
  }

  void _showUpdateDownloadDialog(BuildContext context) {
    final info = ref.read(updateProvider).latestUpdate!;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.updateAvailable),
        content: Text(l10n.newVersionAvailable(info.version)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.updateLater),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startDownload(context);
            },
            child: Text(l10n.installUpdate),
          ),
        ],
      ),
    );
  }

  void _startDownload(BuildContext context) {
    final notifier = ref.read(updateProvider.notifier);
    notifier.downloadUpdate();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(updateProvider);

          if (state.status == UpdateStatus.ready && state.apkPath != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(ctx).pop();
              _installApk(state.apkPath!);
            });
            return const AlertDialog(
              title: Text('Ready'),
              content: Text('Opening installer…'),
            );
          }

          if (state.status == UpdateStatus.error) {
            return AlertDialog(
              title: Text('Download Failed'),
              content: Text(state.errorMessage ?? 'Unknown error'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Close'),
                ),
              ],
            );
          }

          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.downloadingUpdate),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                LinearProgressIndicator(value: state.progress),
                const SizedBox(height: 12),
                Text('${(state.progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _installApk(String path) async {
    try {
      const channel = MethodChannel(
        'com.example.mobile_expense_tracker/update',
      );
      await channel.invokeMethod('installApk', {'path': path});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to install update')),
        );
      }
    }
  }
}
