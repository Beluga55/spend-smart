import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/core/models/budget.dart';
import 'package:mobile_expense_tracker/core/models/saving_goal.dart';
import 'package:mobile_expense_tracker/core/models/recurring_expense.dart';
import 'package:mobile_expense_tracker/core/models/income.dart';
import 'package:mobile_expense_tracker/core/models/wallet.dart';
import 'package:mobile_expense_tracker/core/models/wallet_transfer.dart';
import 'package:mobile_expense_tracker/core/models/group.dart';
import 'package:mobile_expense_tracker/core/models/group_member.dart';
import 'package:mobile_expense_tracker/core/models/group_expense.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_split.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_item.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/features/home_screen.dart';
import 'package:mobile_expense_tracker/features/onboarding/onboarding_screen.dart';
import 'package:mobile_expense_tracker/features/splash/splash_screen.dart';
import 'package:mobile_expense_tracker/core/constants/app_constants.dart';
import 'package:mobile_expense_tracker/core/providers/locale_provider.dart';
import 'package:mobile_expense_tracker/core/providers/theme_provider.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:mobile_expense_tracker/core/services/notification_service.dart';
import 'package:mobile_expense_tracker/core/services/biometric_service.dart';
import 'package:mobile_expense_tracker/core/services/hive_init_service.dart';
import 'package:mobile_expense_tracker/core/services/update_service.dart';
import 'package:mobile_expense_tracker/core/services/home_widget_service.dart';
import 'package:mobile_expense_tracker/core/config/env.dart';
import 'package:mobile_expense_tracker/core/providers/update_provider.dart';
import 'package:mobile_expense_tracker/core/database/database_migration_service.dart';
import 'package:mobile_expense_tracker/features/lock/lock_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load secrets from .env before anything else needs them.
  await Env.load();

  await Hive.initFlutter();

  // Register adapters safely — typeId conflicts from old builds can crash here
  _safeRegisterAdapter<Expense>(0, () => ExpenseAdapter());
  _safeRegisterAdapter<Category>(1, () => CategoryAdapter());
  _safeRegisterAdapter<Budget>(2, () => BudgetAdapter());
  _safeRegisterAdapter<SavingGoal>(3, () => SavingGoalAdapter());
  _safeRegisterAdapter<RecurringExpense>(4, () => RecurringExpenseAdapter());
  _safeRegisterAdapter<RecurringFrequency>(5, () => RecurringFrequencyAdapter());
  _safeRegisterAdapter<Income>(6, () => IncomeAdapter());
  _safeRegisterAdapter<Wallet>(7, () => WalletAdapter());
  _safeRegisterAdapter<WalletTransfer>(8, () => WalletTransferAdapter());
  _safeRegisterAdapter<Group>(9, () => GroupAdapter());
  _safeRegisterAdapter<GroupMember>(10, () => GroupMemberAdapter());
  _safeRegisterAdapter<GroupExpense>(11, () => GroupExpenseAdapter());
  _safeRegisterAdapter<GroupExpenseSplit>(12, () => GroupExpenseSplitAdapter());
  _safeRegisterAdapter<GroupExpenseItem>(13, () => GroupExpenseItemAdapter());

  // Open all boxes with corruption recovery.
  // This is the #1 cause of "stuck on splash screen" after app updates
  // on Samsung and other devices — old Hive data no longer deserializes.
  await openBoxSafe<Expense>('expenses');
  await openBoxSafe<Category>('categories');
  await openBoxSafe<Budget>('budgets');
  await openBoxSafe<SavingGoal>('saving_goals');
  await openBoxSafe<RecurringExpense>('recurring_expenses');
  await openBoxSafe<Income>('incomes');
  await openBoxSafe<Wallet>('wallets');
  await openBoxSafe<WalletTransfer>('wallet_transfers');
  await openBoxSafe<Group>('groups');
  await openBoxSafe<GroupMember>('group_members');
  await openBoxSafe<GroupExpense>('group_expenses');
  await openBoxSafe<GroupExpenseSplit>('group_expense_splits');
  await openBoxSafe<GroupExpenseItem>('group_expense_items');
  await openBoxSafeUntyped('settings');

  // Run migrations to patch old schema before business logic touches the data.
  await runMigrations();

  runApp(
    const ProviderScope(
      child: AppInitializer(),
    ),
  );
}

void _safeRegisterAdapter<T>(int typeId, TypeAdapter<T> Function() factory) {
  try {
    if (!Hive.isAdapterRegistered(typeId)) {
      Hive.registerAdapter(factory());
    }
  } catch (e) {
    debugPrint('[Hive] Adapter registration error for typeId $typeId: $e');
  }
}

class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  bool _initialized = false;
  bool _showOnboarding = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      await _seedData();
      await Future.delayed(Duration.zero);

      await _processRecurringExpenses();
      await Future.delayed(Duration.zero);

      await _processMonthlyCarryover();
      await Future.delayed(Duration.zero);

      await _initializeServices();

      await Future.delayed(Duration.zero);

      // Push initial data to the home screen widget
      await HomeWidgetService.updateBalanceWidget();

      final settingsBox = Hive.box('settings');
      final onboardingComplete =
          settingsBox.get('onboardingComplete', defaultValue: false) == true;

      if (mounted) {
        setState(() {
          _showOnboarding = !onboardingComplete;
          _initialized = true;
        });
        _checkForAppUpdate();
      }
    } catch (e, stack) {
      debugPrint('Initialization error: $e');
      debugPrint(stack.toString());
      if (mounted) {
        setState(() {
          _initError = e.toString();
          _showOnboarding = false;
          _initialized = true;
        });
      }
    }
  }

  Future<void> _seedData() async {
    final categoryBox = Hive.box<Category>('categories');
    if (categoryBox.isEmpty) {
      const uuid = Uuid();
      for (final cat in AppConstants.defaultCategories) {
        final id = uuid.v4();
        await categoryBox.put(
          id,
          Category(
            id: id,
            name: cat.name,
            iconName: cat.iconName,
            color: cat.color,
            isDefault: true,
            categoryType: 'expense',
          ),
        );
      }
      for (final cat in AppConstants.defaultIncomeCategories) {
        final id = uuid.v4();
        await categoryBox.put(
          id,
          Category(
            id: id,
            name: cat.name,
            iconName: cat.iconName,
            color: cat.color,
            isDefault: true,
            categoryType: 'income',
          ),
        );
      }
    }

    // Seed default income categories if they don't exist yet (migration)
    final hasIncomeCategories = categoryBox.values.any(
      (c) => c.effectiveType == 'income',
    );
    if (!hasIncomeCategories) {
      const uuid = Uuid();
      for (final cat in AppConstants.defaultIncomeCategories) {
        final id = uuid.v4();
        await categoryBox.put(
          id,
          Category(
            id: id,
            name: cat.name,
            iconName: cat.iconName,
            color: cat.color,
            isDefault: true,
            categoryType: 'income',
          ),
        );
      }
    }

    // Fix mismatched box keys
    final keysToFix = <dynamic, Category>{};
    for (final key in categoryBox.keys) {
      final cat = categoryBox.get(key);
      if (cat != null && cat.id != key) {
        keysToFix[key] = cat;
      }
    }
    for (final entry in keysToFix.entries) {
      await categoryBox.delete(entry.key);
      await categoryBox.put(entry.value.id, entry.value);
    }

    // Remove duplicate categories
    final seen = <String>{};
    final dupeKeys = <dynamic>[];
    for (final key in categoryBox.keys) {
      final cat = categoryBox.get(key);
      if (cat != null) {
        final uniqueKey = '${cat.name.toLowerCase()}_${cat.effectiveType}';
        if (seen.contains(uniqueKey)) {
          dupeKeys.add(key);
        } else {
          seen.add(uniqueKey);
        }
      }
    }
    for (final key in dupeKeys) {
      await categoryBox.delete(key);
    }

    // Seed default wallet if none exist
    final walletBox = Hive.box<Wallet>('wallets');
    if (walletBox.isEmpty) {
      const uuid = Uuid();
      final id = uuid.v4();
      await walletBox.put(
        id,
        Wallet(
          id: id,
          name: 'Cash',
          iconName: 'wallet',
          color: 0xFF4CAF50,
          type: 'cash',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _initializeServices() async {
    // NUCLEAR FIX: Reset auth state on every app version change.
    // This guarantees we never carry a stale/corrupt auth session across
    // updates (sideload, in-app updater, or Play Store).  Local data
    // (expenses, categories, budgets, wallets) is fully preserved.
    // The user simply taps "Sign in with Google" once after updating.
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      final settingsBox = Hive.box('settings');
      final lastVersion = settingsBox.get('lastAppVersion') as String?;
      if (lastVersion != currentVersion) {
        debugPrint('[Auth] Version changed ($lastVersion → $currentVersion). Resetting auth state.');
        await SupabaseService.forceRefreshAuth();
        await settingsBox.delete('googleLinked');
        await settingsBox.delete('googleEmail');
        await settingsBox.put('lastAppVersion', currentVersion);
      }
    } catch (e) {
      debugPrint('Version-based auth reset failed: $e');
    }

    // Initialize Supabase with timeout (Samsung network can be slow/aggressive)
    try {
      await SupabaseService.initialize()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Supabase initialization failed or timed out: $e');
    }

    // Initialize Google Sign-In with timeout and error isolation
    try {
      await GoogleSignIn.instance
          .initialize(serverClientId: AppConstants.googleWebClientId)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Google Sign-In initialization failed or timed out: $e');
    }

    // Create anonymous session if none exists
    try {
      final currentSession = SupabaseService.client.auth.currentSession;
      if (currentSession == null) {
        await SupabaseService.signInAnonymously()
            .timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('Anonymous sign-in failed or timed out: $e');
    }

    // Safety: if session recovery failed and we're now anonymous,
    // but stale Hive flags still say Google-linked, clear them.
    // This prevents the "Email linked but can't unlink" bug after updates.
    try {
      final user = SupabaseService.client.auth.currentUser;
      final isAnonymous = user == null || user.isAnonymous;
      if (isAnonymous) {
        final settingsBox = Hive.box('settings');
        final hiveLinked = settingsBox.get('googleLinked', defaultValue: false) == true;
        if (hiveLinked) {
          await settingsBox.delete('googleLinked');
          await settingsBox.delete('googleEmail');
          debugPrint('[Auth] Cleared stale googleLinked flags after anonymous recovery');
        }
      }
    } catch (e) {
      debugPrint('Auth flag cleanup failed: $e');
    }

    // Initialize home widget background callback
    await HomeWidgetService.initialize();

    // Initialize notifications (fast, local)
    await NotificationService.initialize();

    // Request notification permission before scheduling
    final permissionGranted = await NotificationService.requestPermission();
    if (permissionGranted == false) {
      debugPrint('[Notifications] Permission denied on Android 13+ — scheduled reminders will be blocked by OS');
    }

    // Schedule reminder if enabled
    final settingsBox = Hive.box('settings');
    if (settingsBox.get('reminderEnabled', defaultValue: true) == true) {
      final hour = settingsBox.get('reminderHour', defaultValue: 20) as int;
      final minute = settingsBox.get('reminderMinute', defaultValue: 0) as int;
      await NotificationService.scheduleDailyReminder(
        TimeOfDay(hour: hour, minute: minute),
      );
    }
  }

  Future<void> _processRecurringExpenses() async {
    final recurringBox = Hive.box<RecurringExpense>('recurring_expenses');
    final expenseBox = Hive.box<Expense>('expenses');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const maxBacklogDays = 180;
    const uuid = Uuid();

    for (final recurring in recurringBox.values) {
      if (!recurring.isActive) continue;

      final startDay = DateTime(
        recurring.startDate.year,
        recurring.startDate.month,
        recurring.startDate.day,
      );
      if (startDay.isAfter(today)) continue;

      var current = recurring;
      var nextDate =
          current.lastCreated == null ? startDay : current.getNextDueDate();

      int iterations = 0;
      while (nextDate != null && !nextDate.isAfter(today) && iterations < maxBacklogDays) {
        final expense = Expense(
          id: uuid.v4(),
          amount: current.amount,
          categoryId: current.categoryId,
          date: nextDate,
          note: current.note,
          createdAt: now,
        );
        await expenseBox.put(expense.id, expense);

        current = current.copyWith(lastCreated: nextDate);
        await recurringBox.put(current.id, current);

        nextDate = current.getNextDueDate();
        iterations++;
      }

      if (iterations >= maxBacklogDays) {
        debugPrint('[Recurring] Capped backlog at $maxBacklogDays days for "${current.note}"');
      }
    }
  }

  Future<void> _processMonthlyCarryover() async {
    final settings = Hive.box('settings');
    final now = DateTime.now();
    final currentMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final lastProcessedStr = settings.get('carryoverMonth') as String?;

    // Build the list of month keys to process.
    // If we have a stored value, process all months from that month
    // (exclusive) up to currentMonthKey (exclusive).
    // If no stored value, only process the single previous month.
    final monthsToProcess = <String>[];

    if (lastProcessedStr == currentMonthKey) return;

    // Determine starting month
    DateTime cursor;
    if (lastProcessedStr != null) {
      final parts = lastProcessedStr.split('-');
      cursor = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    } else {
      // First run: only process previous month
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      monthsToProcess.add('$prevYear-${prevMonth.toString().padLeft(2, '0')}');
      await _createCarryoverForMonth(prevYear, prevMonth, now);
      await settings.put('carryoverMonth', currentMonthKey);
      return;
    }

    // Walk forward from cursor (exclusive) to current month (exclusive)
    while (true) {
      final nextYear = cursor.month == 12 ? cursor.year + 1 : cursor.year;
      final nextMonth = cursor.month == 12 ? 1 : cursor.month + 1;
      final nextKey = '$nextYear-${nextMonth.toString().padLeft(2, '0')}';
      if (nextKey == currentMonthKey) break;
      monthsToProcess.add(nextKey);
      cursor = DateTime(nextYear, nextMonth);
    }

    for (final monthKey in monthsToProcess) {
      final parts = monthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      await _createCarryoverForMonth(year, month, now);
    }

    await settings.put('carryoverMonth', currentMonthKey);
  }

  Future<void> _createCarryoverForMonth(int year, int month, DateTime now) async {
    final incomeBox = Hive.box<Income>('incomes');
    final expenseBox = Hive.box<Expense>('expenses');

    final monthIncome = incomeBox.values
        .where((i) => i.date.year == year && i.date.month == month)
        .fold(0.0, (sum, i) => sum + i.amount);

    final monthExpenses = expenseBox.values
        .where((e) => e.date.year == year && e.date.month == month)
        .fold(0.0, (sum, e) => sum + e.amount);

    final net = monthIncome - monthExpenses;

    if (net == 0) return;

    final monthLabel = DateFormat('MMMM yyyy').format(DateTime(year, month));
    final firstOfMonth = DateTime(now.year, now.month, 1);
    const uuid = Uuid();

    if (net > 0) {
      final income = Income(
        id: uuid.v4(),
        amount: net,
        source: 'Carryover from $monthLabel',
        date: firstOfMonth,
        createdAt: now,
      );
      await incomeBox.put(income.id, income);
    } else {
      final categoryBox = Hive.box<Category>('categories');
      final otherCat = categoryBox.values.firstWhere(
        (c) => c.name == 'Other' && c.effectiveType == 'expense',
        orElse: () => categoryBox.values.firstWhere(
          (c) => c.effectiveType == 'expense',
          orElse: () => Category(
            id: '',
            name: 'Unknown',
            iconName: 'help_outline',
            color: 0xFF999999,
            isDefault: true,
            categoryType: 'expense',
          ),
        ),
      );
      final expense = Expense(
        id: uuid.v4(),
        amount: net.abs(),
        categoryId: otherCat.id.isEmpty ? 'unknown' : otherCat.id,
        date: firstOfMonth,
        note: 'Deficit from $monthLabel',
        createdAt: now,
      );
      await expenseBox.put(expense.id, expense);
    }
  }

  Future<void> _checkForAppUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      await ref.read(updateProvider.notifier).checkForUpdate(currentVersion);
      final info = ref.read(updateProvider).latestUpdate;
      if (info != null && mounted) {
        _showUpdateDialog(info);
      }
    } catch (_) {}
  }

  void _showUpdateDialog(UpdateInfo info) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Available'),
        content: Text(
          'New version ${info.version} is available.\n\n'
          '${info.releaseNotes.isNotEmpty ? info.releaseNotes : ''}',
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadAndInstall(info);
            },
            child: const Text('Install Update'),
          ),
        ],
      ),
    );
  }

  void _downloadAndInstall(UpdateInfo info) {
    if (!mounted) return;
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
              title: const Text('Download Failed'),
              content: Text(state.errorMessage ?? 'Unknown error'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          }

          return AlertDialog(
            title: const Text('Downloading Update'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please wait while the update downloads…'),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: state.progress),
                const SizedBox(height: 8),
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
      const channel = MethodChannel('com.example.mobile_expense_tracker/update');
      await channel.invokeMethod('installApk', {'path': path});
    } catch (e) {
      debugPrint('Install error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      );
    }

    // If init failed catastrophically, show a minimal error screen
    // instead of a blank screen so users know what happened
    if (_initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to start app',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _initError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initError = null;
                        _initialized = false;
                      });
                      _initializeApp();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ExpenseTrackerApp(showOnboarding: _showOnboarding);
  }
}

class ExpenseTrackerApp extends ConsumerStatefulWidget {
  final bool showOnboarding;
  const ExpenseTrackerApp({super.key, required this.showOnboarding});

  @override
  ConsumerState<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends ConsumerState<ExpenseTrackerApp> {
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _isLocked = BiometricService.isEnabled();
  }

  void _onUnlocked() {
    setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);
    final themeStyle = ref.watch(themeStyleProvider);
    final isCat = themeStyle == ThemeStyle.catTheme;

    return MaterialApp(
      title: AppConstants.appName,
      theme: isCat ? AppTheme.catLightTheme : AppTheme.lightTheme,
      darkTheme: isCat ? AppTheme.catDarkTheme : AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('zh')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _isLocked
          ? LockScreen(onUnlocked: _onUnlocked)
          : widget.showOnboarding
              ? const OnboardingScreen()
              : const HomeScreen(),
    );
  }
}
