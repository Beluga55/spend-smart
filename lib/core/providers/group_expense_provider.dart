import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/models/group_expense.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_split.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_item.dart';
import 'package:mobile_expense_tracker/core/services/group_sync_service.dart';

final groupExpenseBoxProvider = Provider<Box<GroupExpense>>((ref) {
  return Hive.box<GroupExpense>('group_expenses');
});

final groupExpenseSplitBoxProvider = Provider<Box<GroupExpenseSplit>>((ref) {
  return Hive.box<GroupExpenseSplit>('group_expense_splits');
});

final groupExpenseItemBoxProvider = Provider<Box<GroupExpenseItem>>((ref) {
  return Hive.box<GroupExpenseItem>('group_expense_items');
});

final groupExpensesProvider =
    StateNotifierProvider.family<
      GroupExpensesNotifier,
      List<GroupExpense>,
      String
    >((ref, groupId) {
      final box = ref.watch(groupExpenseBoxProvider);
      final syncService = ref.watch(groupSyncServiceProvider);
      return GroupExpensesNotifier(box, groupId, syncService);
    });

class GroupExpensesNotifier extends StateNotifier<List<GroupExpense>> {
  final Box<GroupExpense> _box;
  final String _groupId;
  final GroupSyncService _syncService;

  GroupExpensesNotifier(this._box, this._groupId, this._syncService)
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
    return _syncService.pushExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
    _refresh();
    return _syncService.deleteExpense(id);
  }
}

final groupExpenseSplitsProvider =
    StateNotifierProvider.family<
      GroupExpenseSplitsNotifier,
      List<GroupExpenseSplit>,
      String
    >((ref, groupExpenseId) {
      final box = ref.watch(groupExpenseSplitBoxProvider);
      final syncService = ref.watch(groupSyncServiceProvider);
      return GroupExpenseSplitsNotifier(box, groupExpenseId, syncService);
    });

class GroupExpenseSplitsNotifier
    extends StateNotifier<List<GroupExpenseSplit>> {
  final Box<GroupExpenseSplit> _box;
  final String _groupExpenseId;
  final GroupSyncService _syncService;

  GroupExpenseSplitsNotifier(this._box, this._groupExpenseId, this._syncService)
    : super(
        _box.values.where((s) => s.groupExpenseId == _groupExpenseId).toList(),
      ) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() {
    state = _box.values
        .where((s) => s.groupExpenseId == _groupExpenseId)
        .toList();
  }

  Future<void> settleSplit(String splitId) async {
    final split = _box.get(splitId);
    if (split != null) {
      final updated = split.copyWith(
        isSettled: true,
        settledAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _box.put(splitId, updated);
      _refresh();
      return _syncService.pushSplit(updated);
    }
  }

  Future<void> addSplit(GroupExpenseSplit split) async {
    await _box.put(split.id, split);
    _refresh();
    return _syncService.pushSplit(split);
  }
}


final groupExpenseItemsProvider =
    StateNotifierProvider.family<
      GroupExpenseItemsNotifier,
      List<GroupExpenseItem>,
      String
    >((ref, groupExpenseId) {
      final box = ref.watch(groupExpenseItemBoxProvider);
      return GroupExpenseItemsNotifier(box, groupExpenseId);
    });

class GroupExpenseItemsNotifier extends StateNotifier<List<GroupExpenseItem>> {
  final Box<GroupExpenseItem> _box;
  final String _groupExpenseId;

  GroupExpenseItemsNotifier(this._box, this._groupExpenseId)
    : super(
        _box.values.where((i) => i.groupExpenseId == _groupExpenseId).toList(),
      ) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() {
    state = _box.values
        .where((i) => i.groupExpenseId == _groupExpenseId)
        .toList();
  }

  Future<void> addItem(GroupExpenseItem item) async {
    await _box.put(item.id, item);
    _refresh();
  }
}

/// Net balance for each user across all group expenses.
///
/// Algorithm: for every *unsettled* split that belongs to someone who did NOT
/// pay for the expense, the payer is owed that amount (+) and the debtor owes
/// that amount (−).  Settled splits are completely excluded, so when every
/// split in a group is settled both parties show $0.
///
/// Old (buggy) formula added the full `totalAmount` to the payer then
/// subtracted unsettled splits — but the payer's own split is created with
/// `isSettled = true`, so it was never subtracted, leaving the payer with a
/// permanently inflated positive balance.
final groupBalancesProvider = Provider.family<Map<String, double>, String>((
  ref,
  groupId,
) {
  final expenses = ref.watch(groupExpensesProvider(groupId));
  final balances = <String, double>{};

  for (final expense in expenses) {
    final splits = ref.watch(groupExpenseSplitsProvider(expense.id));
    for (final split in splits) {
      // Only consider unsettled splits from non-payers (true debts).
      if (split.isSettled) continue;
      if (split.userId == expense.paidByUserId) continue;

      // Payer is owed this amount; debtor owes it.
      balances[expense.paidByUserId] =
          (balances[expense.paidByUserId] ?? 0) + split.amount;
      balances[split.userId] = (balances[split.userId] ?? 0) - split.amount;
    }
  }

  return balances;
});
