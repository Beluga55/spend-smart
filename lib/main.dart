import 'package:flutter/material.dart';
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
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/features/home_screen.dart';
import 'package:mobile_expense_tracker/features/onboarding/onboarding_screen.dart';
import 'package:mobile_expense_tracker/core/constants/app_constants.dart';
import 'package:mobile_expense_tracker/core/providers/locale_provider.dart';
import 'package:mobile_expense_tracker/core/providers/theme_provider.dart';import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:mobile_expense_tracker/core/services/notification_service.dart';
import 'package:mobile_expense_tracker/core/services/biometric_service.dart';
import 'package:mobile_expense_tracker/features/lock/lock_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(SavingGoalAdapter());
  Hive.registerAdapter(RecurringExpenseAdapter());
  Hive.registerAdapter(RecurringFrequencyAdapter());
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(WalletAdapter());
  Hive.registerAdapter(WalletTransferAdapter());

  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<Budget>('budgets');
  await Hive.openBox<SavingGoal>('saving_goals');
  await Hive.openBox<RecurringExpense>('recurring_expenses');
  await Hive.openBox<Income>('incomes');
  await Hive.openBox<Wallet>('wallets');
  await Hive.openBox<WalletTransfer>('wallet_transfers');
  await Hive.openBox('settings');

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

  // Seed default income categories if they don't exist yet (migration for existing users)
  final hasIncomeCategories = categoryBox.values.any(
    (c) => c.categoryType == 'income',
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

  // Fix mismatched box keys: ensure each category's box key matches its id
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

  // Remove duplicate categories (same name + same type, keep first)
  final seen = <String>{};
  final dupeKeys = <dynamic>[];
  for (final key in categoryBox.keys) {
    final cat = categoryBox.get(key);
    if (cat != null) {
      final uniqueKey = '${cat.name.toLowerCase()}_${cat.categoryType}';
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

  await _processRecurringExpenses();
  await _processMonthlyCarryover();

  // Initialize Supabase (silent fail if no config)
  try {
    await SupabaseService.initialize();

    // Initialize Google Sign-In (must be called exactly once)
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConstants.googleWebClientId,
    );

    // Only sign in anonymously if there is no saved session (e.g. from Google)
    final currentSession = SupabaseService.client.auth.currentSession;
    if (currentSession == null) {
      await SupabaseService.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Supabase initialization skipped: $e');
  }

  final settingsBox = Hive.box('settings');
  final showOnboarding = settingsBox.get('onboardingComplete', defaultValue: false) != true;

  // Initialize notifications and schedule if enabled
  await NotificationService.initialize();
  if (settingsBox.get('reminderEnabled', defaultValue: true) == true) {
    final hour = settingsBox.get('reminderHour', defaultValue: 20) as int;
    final minute = settingsBox.get('reminderMinute', defaultValue: 0) as int;
    await NotificationService.scheduleDailyReminder(TimeOfDay(hour: hour, minute: minute));
  }

  runApp(ProviderScope(child: ExpenseTrackerApp(showOnboarding: showOnboarding)));
}

Future<void> _processRecurringExpenses() async {
  final recurringBox = Hive.box<RecurringExpense>('recurring_expenses');
  final expenseBox = Hive.box<Expense>('expenses');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (final recurring in recurringBox.values) {
    if (!recurring.isActive) continue;

    final startDay = DateTime(
      recurring.startDate.year,
      recurring.startDate.month,
      recurring.startDate.day,
    );
    if (startDay.isAfter(today)) continue;

    // Generate all missed occurrences with correct dates
    var current = recurring;
    var nextDate = current.lastCreated == null ? startDay : current.getNextDueDate();

    while (nextDate != null && !nextDate.isAfter(today)) {
      const uuid = Uuid();
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
    }
  }
}

Future<void> _processMonthlyCarryover() async {
  final settings = Hive.box('settings');
  final now = DateTime.now();
  final currentMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

  if (settings.get('carryoverMonth') == currentMonthKey) return;

  final prevYear = now.month == 1 ? now.year - 1 : now.year;
  final prevMonth = now.month == 1 ? 12 : now.month - 1;

  final incomeBox = Hive.box<Income>('incomes');
  final expenseBox = Hive.box<Expense>('expenses');

  final prevIncome = incomeBox.values
      .where((i) => i.date.year == prevYear && i.date.month == prevMonth)
      .fold(0.0, (sum, i) => sum + i.amount);

  final prevExpenses = expenseBox.values
      .where((e) => e.date.year == prevYear && e.date.month == prevMonth)
      .fold(0.0, (sum, e) => sum + e.amount);

  final net = prevIncome - prevExpenses;
  final monthLabel = DateFormat('MMMM yyyy').format(DateTime(prevYear, prevMonth));
  const uuid = Uuid();
  final firstOfMonth = DateTime(now.year, now.month, 1);

  if (net > 0) {
    final income = Income(
      id: uuid.v4(),
      amount: net,
      source: 'Carryover from $monthLabel',
      date: firstOfMonth,
      createdAt: now,
    );
    await incomeBox.put(income.id, income);
  } else if (net < 0) {
    final categoryBox = Hive.box<Category>('categories');
    final otherCat = categoryBox.values.firstWhere(
      (c) => c.name == 'Other' && c.categoryType == 'expense',
      orElse: () => categoryBox.values.firstWhere(
        (c) => c.categoryType == 'expense',
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

  await settings.put('carryoverMonth', currentMonthKey);
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
