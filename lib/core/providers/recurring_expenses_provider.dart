import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/models/recurring_expense.dart';
import 'package:uuid/uuid.dart';

final recurringExpenseBoxProvider = Provider<Box<RecurringExpense>>((ref) {
  return Hive.box<RecurringExpense>('recurring_expenses');
});

final recurringExpensesProvider = StateNotifierProvider<RecurringExpensesNotifier, List<RecurringExpense>>((ref) {
  final box = ref.watch(recurringExpenseBoxProvider);
  return RecurringExpensesNotifier(box);
});

class RecurringExpensesNotifier extends StateNotifier<List<RecurringExpense>> {
  final Box<RecurringExpense> _box;

  RecurringExpensesNotifier(this._box) : super(_box.values.toList()) {
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

  Future<void> markAsAdded(String id) async {
    final recurring = _box.get(id);
    if (recurring != null) {
      final updated = recurring.copyWith(lastCreated: DateTime.now());
      await _box.put(id, updated);
      _refresh();
    }
  }
}

final activeRecurringExpensesProvider = Provider<List<RecurringExpense>>((ref) {
  final recurring = ref.watch(recurringExpensesProvider);
  return recurring.where((r) => r.isActive).toList();
});