import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/core/models/budget.dart';
import 'package:mobile_expense_tracker/core/models/income.dart';
import 'package:mobile_expense_tracker/core/models/recurring_expense.dart';
import 'package:mobile_expense_tracker/core/services/home_widget_service.dart';
import 'package:uuid/uuid.dart';

final expenseBoxProvider = Provider<Box<Expense>>((ref) {
  return Hive.box<Expense>('expenses');
});

final categoryBoxProvider = Provider<Box<Category>>((ref) {
  return Hive.box<Category>('categories');
});

final budgetBoxProvider = Provider<Box<Budget>>((ref) {
  return Hive.box<Budget>('budgets');
});

final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<Expense>>(
  (ref) {
    final box = ref.watch(expenseBoxProvider);
    return ExpensesNotifier(box);
  },
);

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  final Box<Expense> _box;

  ExpensesNotifier(this._box) : super(_box.values.toList()) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() {
    state = _box.values.toList();
  }

  Future<void> addExpense({
    required double amount,
    required String categoryId,
    required DateTime date,
    String? note,
    String? walletId,
    String? receiptImagePath,
  }) async {
    const uuid = Uuid();
    final expense = Expense(
      id: uuid.v4(),
      amount: amount,
      categoryId: categoryId,
      date: date,
      note: note,
      createdAt: DateTime.now(),
      walletId: walletId,
      receiptImagePath: receiptImagePath,
    );
    await _box.put(expense.id, expense);
    _refresh();
    HomeWidgetService.updateBalanceWidget();
  }

  Future<void> updateExpense(Expense expense) async {
    await _box.put(expense.id, expense);
    _refresh();
    HomeWidgetService.updateBalanceWidget();
  }

  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
    _refresh();
    HomeWidgetService.updateBalanceWidget();
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>((ref) {
      final box = ref.watch(categoryBoxProvider);
      return CategoriesNotifier(box);
    });

class CategoriesNotifier extends StateNotifier<List<Category>> {
  final Box<Category> _box;

  CategoriesNotifier(this._box) : super(_box.values.toList()) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() {
    state = _box.values.toList();
  }

  Future<void> addCategory({
    required String name,
    required String iconName,
    required int color,
    String categoryType = 'expense',
  }) async {
    const uuid = Uuid();
    final category = Category(
      id: uuid.v4(),
      name: name,
      iconName: iconName,
      color: color,
      isDefault: false,
      categoryType: categoryType,
    );
    await _box.put(category.id, category);
    _refresh();
  }

  Future<void> updateCategory(Category category) async {
    await _box.put(category.id, category);
    _refresh();
  }

  Future<void> deleteCategory(String id) async {
    final category = _box.get(id);
    if (category != null && !category.isDefault) {
      await _box.delete(id);
      _refresh();
    }
  }
}

final expenseCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesProvider);
  return categories.where((c) => c.effectiveType == 'expense').toList();
});

final incomeCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesProvider);
  return categories.where((c) => c.effectiveType == 'income').toList();
});

final globalBudgetProvider =
    StateNotifierProvider<GlobalBudgetNotifier, Budget?>((ref) {
      final box = ref.watch(budgetBoxProvider);
      final selectedMonth = ref.watch(selectedMonthProvider);
      return GlobalBudgetNotifier(box, selectedMonth.month, selectedMonth.year);
    });

class GlobalBudgetNotifier extends StateNotifier<Budget?> {
  final Box<Budget> _box;
  final int _month;
  final int _year;

  GlobalBudgetNotifier(this._box, this._month, this._year) : super(null) {
    _loadBudget();
    _box.listenable().addListener(_loadBudget);
  }

  void _loadBudget() {
    final budgets = _box.values.where(
      (b) =>
          b.month == _month &&
          b.year == _year &&
          b.categoryId == null &&
          b.day == null,
    );
    state = budgets.isNotEmpty ? budgets.first : null;
  }

  Future<void> setBudget(double amount) async {
    final existing = _box.values.where(
      (b) =>
          b.month == _month &&
          b.year == _year &&
          b.categoryId == null &&
          b.day == null,
    );

    const uuid = Uuid();
    if (existing.isNotEmpty) {
      final budget = existing.first.copyWith(limitAmount: amount);
      await _box.put(budget.id, budget);
    } else {
      final budget = Budget(
        id: uuid.v4(),
        month: _month,
        year: _year,
        limitAmount: amount,
      );
      await _box.put(budget.id, budget);
    }
    _loadBudget();
  }

  Future<void> deleteBudget() async {
    if (state != null) {
      await _box.delete(state!.id);
      _loadBudget();
    }
  }
}

final categoryBudgetsProvider =
    StateNotifierProvider<CategoryBudgetsNotifier, List<Budget>>((ref) {
      final box = ref.watch(budgetBoxProvider);
      final selectedMonth = ref.watch(selectedMonthProvider);
      return CategoryBudgetsNotifier(
        box,
        selectedMonth.month,
        selectedMonth.year,
      );
    });

class CategoryBudgetsNotifier extends StateNotifier<List<Budget>> {
  final Box<Budget> _box;
  final int _month;
  final int _year;

  CategoryBudgetsNotifier(this._box, this._month, this._year) : super([]) {
    _loadBudgets();
    _box.listenable().addListener(_loadBudgets);
  }

  void _loadBudgets() {
    state = _box.values
        .where(
          (b) =>
              b.month == _month &&
              b.year == _year &&
              b.categoryId != null &&
              b.day == null,
        )
        .toList();
  }

  Budget? getBudgetForCategory(String categoryId) {
    return _box.values
        .where(
          (b) =>
              b.month == _month &&
              b.year == _year &&
              b.categoryId == categoryId &&
              b.day == null,
        )
        .firstOrNull;
  }

  Future<void> setBudgetForCategory(String categoryId, double amount) async {
    final existing = _box.values.where(
      (b) =>
          b.month == _month &&
          b.year == _year &&
          b.categoryId == categoryId &&
          b.day == null,
    );

    const uuid = Uuid();
    if (existing.isNotEmpty) {
      final budget = existing.first.copyWith(limitAmount: amount);
      await _box.put(budget.id, budget);
    } else {
      final budget = Budget(
        id: uuid.v4(),
        month: _month,
        year: _year,
        limitAmount: amount,
        categoryId: categoryId,
      );
      await _box.put(budget.id, budget);
    }
    _loadBudgets();
  }

  Future<void> deleteBudgetForCategory(String categoryId) async {
    final existing = _box.values.where(
      (b) =>
          b.month == _month &&
          b.year == _year &&
          b.categoryId == categoryId &&
          b.day == null,
    );
    for (final budget in existing) {
      await _box.delete(budget.id);
    }
    _loadBudgets();
  }
}

final monthlyExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  return expenses
      .where(
        (e) =>
            e.date.month == selectedMonth.month &&
            e.date.year == selectedMonth.year,
      )
      .toList();
});

final monthlyTotalProvider = Provider<double>((ref) {
  final monthlyExpenses = ref.watch(monthlyExpensesProvider);
  return monthlyExpenses.fold(0, (sum, e) => sum + e.amount);
});

final categoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final monthlyExpenses = ref.watch(monthlyExpensesProvider);
  final totals = <String, double>{};
  for (final expense in monthlyExpenses) {
    totals[expense.categoryId] =
        (totals[expense.categoryId] ?? 0) + expense.amount;
  }
  return totals;
});

final globalBudgetProgressProvider = Provider<double>((ref) {
  final globalBudget = ref.watch(globalBudgetProvider);
  final total = ref.watch(monthlyTotalProvider);
  if (globalBudget == null || globalBudget.limitAmount == 0) return 0;
  return (total / globalBudget.limitAmount * 100).clamp(0, 100);
});

final categoryBudgetProgressProvider = Provider.family<double, String>((
  ref,
  categoryId,
) {
  final categoryBudgets = ref.watch(categoryBudgetsProvider);
  final categoryTotals = ref.watch(categoryTotalsProvider);

  final budget = categoryBudgets
      .where((b) => b.categoryId == categoryId)
      .firstOrNull;
  if (budget == null || budget.limitAmount == 0) return 0;

  final spent = categoryTotals[categoryId] ?? 0;
  return (spent / budget.limitAmount * 100).clamp(0, 100);
});

final recentExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(monthlyExpensesProvider);
  final sorted = List<Expense>.from(expenses)
    ..sort((a, b) => b.date.compareTo(a.date));
  return sorted.take(5).toList();
});

final dailySpendingProvider = Provider<Map<DateTime, double>>((ref) {
  final expenses = ref.watch(monthlyExpensesProvider);
  final dailyTotals = <DateTime, double>{};
  for (final expense in expenses) {
    final dateOnly = DateTime(
      expense.date.year,
      expense.date.month,
      expense.date.day,
    );
    dailyTotals[dateOnly] = (dailyTotals[dateOnly] ?? 0) + expense.amount;
  }
  return dailyTotals;
});

final monthlyHistoryProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final monthlyTotals = <String, double>{};

  for (final expense in expenses) {
    final key =
        '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
    monthlyTotals[key] = (monthlyTotals[key] ?? 0) + expense.amount;
  }

  final sortedKeys = monthlyTotals.keys.toList()..sort((a, b) => b.compareTo(a));
  final result = <String, double>{};
  for (final key in sortedKeys.take(6)) {
    result[key] = monthlyTotals[key]!;
  }
  return result;
});

final budgetAlertProvider = Provider<Map<String, String>>((ref) {
  final alerts = <String, String>{};

  final globalBudget = ref.watch(globalBudgetProvider);
  final globalProgress = ref.watch(globalBudgetProgressProvider);

  if (globalBudget != null && globalProgress >= 100) {
    alerts['global'] = 'Monthly budget exceeded!';
  } else if (globalBudget != null && globalProgress >= 80) {
    alerts['global'] = 'Approaching monthly limit';
  }

  final categoryBudgets = ref.watch(categoryBudgetsProvider);
  final categories = ref.watch(categoriesProvider);

  for (final budget in categoryBudgets) {
    final progress = ref.watch(
      categoryBudgetProgressProvider(budget.categoryId!),
    );
    final category = categories
        .where((c) => c.id == budget.categoryId)
        .firstOrNull;
    final categoryName = category?.name ?? 'Unknown';
    if (progress >= 100) {
      alerts[budget.categoryId!] = '$categoryName budget exceeded!';
    } else if (progress >= 80) {
      alerts[budget.categoryId!] = 'Approaching $categoryName limit';
    }
  }

  return alerts;
});

final dailyAllowanceProvider = Provider<double>((ref) {
  final globalBudget = ref.watch(globalBudgetProvider);
  final monthlyTotal = ref.watch(monthlyTotalProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  if (globalBudget == null || globalBudget.limitAmount == 0) return 0;

  final now = DateTime.now();
  final isCurrentMonth =
      selectedMonth.year == now.year && selectedMonth.month == now.month;

  if (!isCurrentMonth) return 0;

  final daysInMonth = DateTime(
    selectedMonth.year,
    selectedMonth.month + 1,
    0,
  ).day;
  final remaining = globalBudget.limitAmount - monthlyTotal;

  if (remaining <= 0) return 0;

  final daysRemaining = daysInMonth - now.day + 1;
  if (daysRemaining <= 0) return 0;

  return remaining / daysRemaining;
});

final projectedSpendingProvider = Provider<double>((ref) {
  final monthlyTotal = ref.watch(monthlyTotalProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  final now = DateTime.now();
  final isCurrentMonth =
      selectedMonth.year == now.year && selectedMonth.month == now.month;

  if (!isCurrentMonth) return monthlyTotal;

  final daysInMonth = DateTime(
    selectedMonth.year,
    selectedMonth.month + 1,
    0,
  ).day;
  final dayOfMonth = now.day;

  if (dayOfMonth == 0) return monthlyTotal;

  return (monthlyTotal / dayOfMonth) * daysInMonth;
});

final spendingStreakProvider = Provider<Map<String, int>>((ref) {
  final expenses = ref.watch(expensesProvider);

  if (expenses.isEmpty) {
    return {'streak': 0, 'daysSinceLast': 0};
  }

  final sortedExpenses = List<Expense>.from(expenses)
    ..sort((a, b) => b.date.compareTo(a.date));

  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  final uniqueDates = <DateTime>{};
  for (final expense in sortedExpenses) {
    uniqueDates.add(
      DateTime(expense.date.year, expense.date.month, expense.date.day),
    );
  }

  final sortedDates = uniqueDates.toList()..sort((a, b) => b.compareTo(a));

  int streak = 0;
  DateTime checkDate = todayDate;

  while (true) {
    if (sortedDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  final lastExpenseDate = sortedDates.first;
  final daysSinceLast = todayDate.difference(lastExpenseDate).inDays;

  return {'streak': streak, 'daysSinceLast': daysSinceLast};
});

final recurringBoxProvider = Provider<Box<RecurringExpense>>((ref) {
  return Hive.box<RecurringExpense>('recurring_expenses');
});

final recurringExpensesProvider =
    StateNotifierProvider<RecurringExpensesNotifier, List<RecurringExpense>>((
      ref,
    ) {
      final box = ref.watch(recurringBoxProvider);
      return RecurringExpensesNotifier(box, ref);
    });

class RecurringExpensesNotifier extends StateNotifier<List<RecurringExpense>> {
  final Box<RecurringExpense> _box;
  final Ref _ref;

  RecurringExpensesNotifier(this._box, this._ref)
    : super(_box.values.toList()) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() {
    state = _box.values.toList();
  }

  Future<void> addRecurring({
    required double amount,
    required String categoryId,
    required RecurringFrequency frequency,
    required DateTime startDate,
    String? note,
    DateTime? endDate,
  }) async {
    const uuid = Uuid();
    final recurring = RecurringExpense(
      id: uuid.v4(),
      amount: amount,
      categoryId: categoryId,
      frequency: frequency,
      startDate: startDate,
      note: note,
      endDate: endDate,
      lastCreated: null,
      isActive: true,
    );
    await _box.put(recurring.id, recurring);
    _refresh();
  }

  Future<void> updateRecurring(RecurringExpense recurring) async {
    await _box.put(recurring.id, recurring);
    _refresh();
  }

  Future<void> deleteRecurring(String id) async {
    await _box.delete(id);
    _refresh();
  }

  Future<void> toggleActive(String id) async {
    final recurring = _box.get(id);
    if (recurring != null) {
      final updated = recurring.copyWith(isActive: !recurring.isActive);
      await _box.put(id, updated);
      _refresh();
    }
  }

  Future<void> checkAndCreateDueExpenses() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final recurring in _box.values) {
      if (!recurring.isDue()) continue;

      await _ref
          .read(expensesProvider.notifier)
          .addExpense(
            amount: recurring.amount,
            categoryId: recurring.categoryId,
            date: today,
            note: recurring.note,
          );

      final updated = recurring.copyWith(lastCreated: now);
      await _box.put(recurring.id, updated);
    }
    _refresh();
  }
}

// ==================== Income Providers ====================

final incomeBoxProvider = Provider<Box<Income>>((ref) {
  return Hive.box<Income>('incomes');
});

final incomesProvider = StateNotifierProvider<IncomesNotifier, List<Income>>((
  ref,
) {
  final box = ref.watch(incomeBoxProvider);
  return IncomesNotifier(box);
});

class IncomesNotifier extends StateNotifier<List<Income>> {
  final Box<Income> _box;

  IncomesNotifier(this._box) : super(_box.values.toList()) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() {
    state = _box.values.toList();
  }

  Future<void> addIncome({
    required double amount,
    required String source,
    required DateTime date,
    String? note,
    String? walletId,
  }) async {
    const uuid = Uuid();
    final income = Income(
      id: uuid.v4(),
      amount: amount,
      source: source,
      date: date,
      note: note,
      createdAt: DateTime.now(),
      walletId: walletId,
    );
    await _box.put(income.id, income);
    _refresh();
    HomeWidgetService.updateBalanceWidget();
  }

  Future<void> updateIncome(Income income) async {
    await _box.put(income.id, income);
    _refresh();
    HomeWidgetService.updateBalanceWidget();
  }

  Future<void> deleteIncome(String id) async {
    await _box.delete(id);
    _refresh();
    HomeWidgetService.updateBalanceWidget();
  }
}

final monthlyIncomesProvider = Provider<List<Income>>((ref) {
  final incomes = ref.watch(incomesProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  return incomes
      .where(
        (i) =>
            i.date.month == selectedMonth.month &&
            i.date.year == selectedMonth.year,
      )
      .toList();
});

final monthlyIncomeTotalProvider = Provider<double>((ref) {
  final monthlyIncomes = ref.watch(monthlyIncomesProvider);
  return monthlyIncomes.fold(0, (sum, i) => sum + i.amount);
});

final incomeBySourceProvider = Provider<Map<String, double>>((ref) {
  final monthlyIncomes = ref.watch(monthlyIncomesProvider);
  final totals = <String, double>{};
  for (final income in monthlyIncomes) {
    totals[income.source] = (totals[income.source] ?? 0) + income.amount;
  }
  return totals;
});

final recentIncomesProvider = Provider<List<Income>>((ref) {
  final incomes = ref.watch(monthlyIncomesProvider);
  final sorted = List<Income>.from(incomes)
    ..sort((a, b) => b.date.compareTo(a.date));
  return sorted.take(5).toList();
});

final monthlyBalanceProvider = Provider<double>((ref) {
  final income = ref.watch(monthlyIncomeTotalProvider);
  final expense = ref.watch(monthlyTotalProvider);
  return income - expense;
});
