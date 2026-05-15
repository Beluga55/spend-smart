import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/models/group_expense.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_split.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_item.dart';

final groupExpenseBoxProvider = Provider<Box<GroupExpense>>((ref) {
  return Hive.box<GroupExpense>('group_expenses');
});

final groupExpenseSplitBoxProvider = Provider<Box<GroupExpenseSplit>>((ref) {
  return Hive.box<GroupExpenseSplit>('group_expense_splits');
});

final groupExpenseItemBoxProvider = Provider<Box<GroupExpenseItem>>((ref) {
  return Hive.box<GroupExpenseItem>('group_expense_items');
});

final groupExpensesProvider = StateNotifierProvider.family<GroupExpensesNotifier, List<GroupExpense>, String>((ref, groupId) {
  final box = ref.watch(groupExpenseBoxProvider);
  return GroupExpensesNotifier(box, groupId);
});

class GroupExpensesNotifier extends StateNotifier<List<GroupExpense>> {
  final Box<GroupExpense> _box;
  final String _groupId;

  GroupExpensesNotifier(this._box, this._groupId)
      : super(_box.values.where((e) => e.groupId == _groupId).toList()) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() {
    state = _box.values.where((e) => e.groupId == _groupId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addExpense(GroupExpense expense) async {
    await _box.put(expense.id, expense);
    _refresh();
  }

  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
    _refresh();
  }
}

final groupExpenseSplitsProvider = StateNotifierProvider.family<GroupExpenseSplitsNotifier, List<GroupExpenseSplit>, String>((ref, groupExpenseId) {
  final box = ref.watch(groupExpenseSplitBoxProvider);
  return GroupExpenseSplitsNotifier(box, groupExpenseId);
});

class GroupExpenseSplitsNotifier extends StateNotifier<List<GroupExpenseSplit>> {
  final Box<GroupExpenseSplit> _box;
  final String _groupExpenseId;

  GroupExpenseSplitsNotifier(this._box, this._groupExpenseId)
      : super(_box.values.where((s) => s.groupExpenseId == _groupExpenseId).toList()) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() {
    state = _box.values.where((s) => s.groupExpenseId == _groupExpenseId).toList();
  }

  Future<void> settleSplit(String splitId) async {
    final split = _box.get(splitId);
    if (split != null) {
      await _box.put(
        splitId,
        split.copyWith(isSettled: true, settledAt: DateTime.now()),
      );
      _refresh();
    }
  }
}

final groupExpenseItemsProvider = StateNotifierProvider.family<GroupExpenseItemsNotifier, List<GroupExpenseItem>, String>((ref, groupExpenseId) {
  final box = ref.watch(groupExpenseItemBoxProvider);
  return GroupExpenseItemsNotifier(box, groupExpenseId);
});

class GroupExpenseItemsNotifier extends StateNotifier<List<GroupExpenseItem>> {
  final Box<GroupExpenseItem> _box;
  final String _groupExpenseId;

  GroupExpenseItemsNotifier(this._box, this._groupExpenseId)
      : super(_box.values.where((i) => i.groupExpenseId == _groupExpenseId).toList()) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() {
    state = _box.values.where((i) => i.groupExpenseId == _groupExpenseId).toList();
  }
}

final groupBalancesProvider = Provider.family<Map<String, double>, String>((ref, groupId) {
  final expenses = ref.watch(groupExpensesProvider(groupId));
  final splits = <GroupExpenseSplit>[];
  for (final exp in expenses) {
    splits.addAll(
      Hive.box<GroupExpenseSplit>('group_expense_splits')
          .values
          .where((s) => s.groupExpenseId == exp.id),
    );
  }

  final balances = <String, double>{};
  for (final split in splits) {
    if (!split.isSettled) {
      balances[split.userId] = (balances[split.userId] ?? 0) + split.amount;
    }
  }
  return balances;
});
