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
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/features/home_screen.dart';
import 'package:mobile_expense_tracker/core/constants/app_constants.dart';
import 'package:mobile_expense_tracker/core/providers/locale_provider.dart';
import 'package:mobile_expense_tracker/core/providers/theme_provider.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<Budget>('budgets');
  await Hive.openBox<SavingGoal>('saving_goals');
  await Hive.openBox<RecurringExpense>('recurring_expenses');
  await Hive.openBox<Income>('incomes');
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

  await _processRecurringExpenses();

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

  runApp(const ProviderScope(child: ExpenseTrackerApp()));
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

    if (recurring.lastCreated == null ||
        recurring.lastCreated!.month != now.month ||
        recurring.lastCreated!.year != now.year) {
      const uuid = Uuid();
      final expense = Expense(
        id: uuid.v4(),
        amount: recurring.amount,
        categoryId: recurring.categoryId,
        date: today,
        note: recurring.note,
        createdAt: now,
      );
      await expenseBox.put(expense.id, expense);

      final updated = recurring.copyWith(lastCreated: now);
      await recurringBox.put(recurring.id, updated);
    }
  }
}

class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
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
      home: const HomeScreen(),
    );
  }
}
