import 'package:flutter/foundation.dart' hide Category;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_expense_tracker/core/models/group.dart';
import 'package:mobile_expense_tracker/core/models/group_member.dart';
import 'package:mobile_expense_tracker/core/models/group_expense.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_split.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_item.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/core/models/income.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';

class GroupRealtimeService {
  static final GroupRealtimeService instance = GroupRealtimeService._();
  GroupRealtimeService._();

  RealtimeChannel? _channel;
  bool _started = false;
  Set<String> _myGroupIds = {};
  String? _userId;

  // ── Public API ─────────────────────────────────────────────────────

  Future<void> start() async {
    if (_started) return;
    _started = true;

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      debugPrint('[GroupRealtime] No user — skipping');
      return;
    }
    _userId = userId;

    try {
      _myGroupIds = (await _getMyGroupIds(userId)).toSet();
      debugPrint('[GroupRealtime] Starting for ${_myGroupIds.length} groups');
      await _subscribe();
    } catch (e) {
      debugPrint('[GroupRealtime] Failed to start: $e');
    }
  }

  void refreshGroupList() {
    _refreshInternal();
  }

  /// Call this immediately after creating or joining a group to ensure
  /// realtime subscriptions include the new group.
  Future<void> forceRefreshForGroup(String groupId) async {
    _myGroupIds.add(groupId);
    debugPrint('[GroupRealtime] Added group $groupId to subscriptions');
    // Re-subscribe to include the new group filters
    await stop();
    _started = true;
    await _subscribe();
  }

  Future<void> _refreshInternal() async {
    await _refreshGroupIds();
    debugPrint('[GroupRealtime] Refreshed — ${_myGroupIds.length} groups');

    await stop();
    _started = true;
    await _subscribe();
  }

  Future<void> stop() async {
    if (_channel != null) {
      await SupabaseService.client.removeChannel(_channel!);
      _channel = null;
      debugPrint('[GroupRealtime] Unsubscribed');
    }
    _started = false;
  }

  // ── Internal ────────────────────────────────────────────────────────

  Future<void> _subscribe() async {
    final userId = _userId;
    if (userId == null) return;

    // Refresh group list to get current memberships
    await _refreshGroupIds();

    _channel = SupabaseService.client.channel(
      'group-updates-$userId-${DateTime.now().millisecondsSinceEpoch}',
    );

    // Groups — handle deletion (disbanding)
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'groups',
      callback: _handleGroupChange,
    );

    // Own membership changes (joining/leaving groups)
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'group_members',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: _handleMemberChange,
    );

    // Other members in my groups - filter by my group IDs
    for (final groupId in _myGroupIds) {
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'group_members',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'group_id',
          value: groupId,
        ),
        callback: _handleMemberChange,
      );
    }

    // Expenses in my groups - for insert/update
    for (final groupId in _myGroupIds) {
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'group_expenses',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'group_id',
          value: groupId,
        ),
        callback: _handleExpenseChange,
      );
    }

    // Also listen to ALL delete events on group_expenses (no filter, because delete oldRecord may not have group_id)
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'group_expenses',
      callback: _handleExpenseDelete,
    );

    // Splits - we need to listen to all and filter by checking if expense is in my group
    // This is expensive but necessary since splits don't have group_id directly
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'group_expense_splits',
      callback: _handleSplitChange,
    );

    // Items - same issue as splits
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'group_expense_items',
      callback: _handleItemChange,
    );

    _channel!.subscribe((status, error) {
      if (error != null) {
        debugPrint('[GroupRealtime] Status: $status, error: $error');
      } else {
        debugPrint('[GroupRealtime] Status: $status');
      }
    });

    debugPrint('[GroupRealtime] Subscribed to ${_myGroupIds.length} groups');
  }

  Future<void> _refreshGroupIds() async {
    final userId = _userId ?? SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      final ids = await _getMyGroupIds(userId);
      _myGroupIds = ids.toSet();
    } catch (e) {
      debugPrint('[GroupRealtime] Failed to refresh group IDs: $e');
    }
  }

  Future<List<String>> _getMyGroupIds(String userId) async {
    try {
      final rows = await SupabaseService.client
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId)
          .eq('is_active', true);
      return rows.map<String>((r) => r['group_id'] as String).toList();
    } catch (e) {
      debugPrint('[GroupRealtime] Failed to get group IDs: $e');
      return [];
    }
  }

  bool _isMyGroup(String groupId) {
    return _myGroupIds.contains(groupId) ||
        Hive.box<Group>('groups').containsKey(groupId);
  }

  void _handleGroupChange(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.delete) {
      final groupId = payload.oldRecord['id'] as String?;
      if (groupId != null) {
        _cleanupLocalGroupData(groupId);
        debugPrint('[GroupRealtime] Group deleted: $groupId');
      }
    }
  }

  Future<void> _cleanupLocalGroupData(String groupId) async {
    final groupBox = Hive.box<Group>('groups');
    final memberBox = Hive.box<GroupMember>('group_members');
    final expenseBox = Hive.box<GroupExpense>('group_expenses');
    final splitBox = Hive.box<GroupExpenseSplit>('group_expense_splits');
    final itemBox = Hive.box<GroupExpenseItem>('group_expense_items');

    // 1. Delete group record
    await groupBox.delete(groupId);

    // 2. Delete members
    final memberIds = memberBox.values
        .where((m) => m.groupId == groupId)
        .map((m) => m.id)
        .toList();
    for (final id in memberIds) {
      await memberBox.delete(id);
    }

    // 3. Delete expenses, splits, and items
    final groupExpenses = expenseBox.values
        .where((e) => e.groupId == groupId)
        .toList();
    for (final expense in groupExpenses) {
      final sIds = splitBox.values
          .where((s) => s.groupExpenseId == expense.id)
          .map((s) => s.id)
          .toList();
      for (final id in sIds) {
        await splitBox.delete(id);
      }

      final iIds = itemBox.values
          .where((i) => i.groupExpenseId == expense.id)
          .map((i) => i.id)
          .toList();
      for (final id in iIds) {
        await itemBox.delete(id);
      }

      await expenseBox.delete(expense.id);
    }

    _myGroupIds.remove(groupId);
  }

  void _handleMemberChange(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.delete) {
      final oldId = payload.oldRecord['id'] as String?;
      if (oldId != null) {
        Hive.box<GroupMember>('group_members').delete(oldId);
      }
      return;
    }
    final row = payload.newRecord;
    final id = row['id'] as String?;
    if (id == null) return;
    final userId = row['user_id'] as String?;
    final groupId = row['group_id'] as String;
    final currentUserId = SupabaseService.currentUser?.id;

    if (!_isMyGroup(groupId)) {
      if (userId == currentUserId) {
        _myGroupIds.add(groupId);
        _fetchGroup(groupId);
      } else {
        return;
      }
    }

    final member = GroupMember(
      id: id,
      groupId: groupId,
      userId: userId,
      displayName: row['display_name'] as String,
      joinedAt: DateTime.parse(row['joined_at'] as String),
      role: (row['role'] as String?) ?? 'member',
      isActive: (row['is_active'] as bool?) ?? true,
      updatedAt: DateTime.parse(row['updated_at'] as String),
      syncStatus: 'synced',
    );
    Hive.box<GroupMember>('group_members').put(id, member);
  }

  Future<void> _fetchGroup(String groupId) async {
    try {
      final rows = await SupabaseService.client
          .from('groups')
          .select()
          .eq('id', groupId)
          .limit(1);
      if (rows.isNotEmpty) {
        final row = rows.first;
        final groupBox = Hive.box<Group>('groups');
        final group = Group(
          id: row['id'] as String,
          name: row['name'] as String,
          createdBy: row['created_by'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          inviteCode: row['invite_code'] as String,
          isActive: (row['is_active'] as bool?) ?? true,
          updatedAt: DateTime.parse(row['updated_at'] as String),
          syncStatus: 'synced',
        );
        await groupBox.put(group.id, group);
      }
    } catch (e) {
      debugPrint('[GroupRealtime] Failed to fetch group $groupId: $e');
    }
  }

  void _handleExpenseChange(PostgresChangePayload payload) {
    debugPrint(
      '[GroupRealtime] Expense change event: ${payload.eventType.name}, table: ${payload.table}',
    );
    final row = payload.newRecord;
    final id = row['id'] as String?;
    if (id == null) return;
    final groupId = row['group_id'] as String;

    if (!_isMyGroup(groupId)) {
      _myGroupIds.add(groupId);
      _fetchGroup(groupId);
    }

    final expense = GroupExpense(
      id: id,
      groupId: groupId,
      description: row['description'] as String,
      totalAmount: (row['total_amount'] as num).toDouble(),
      date: DateTime.parse(row['date'] as String),
      paidByUserId: row['paid_by_user_id'] as String,
      receiptImagePath: row['receipt_image_path'] as String?,
      syncStatus: 'synced',
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
    Hive.box<GroupExpense>('group_expenses').put(id, expense);
  }

  void _handleExpenseDelete(PostgresChangePayload payload) {
    debugPrint('[GroupRealtime] Expense delete event received');
    final oldId = payload.oldRecord['id'] as String?;
    if (oldId == null) {
      debugPrint('[GroupRealtime] Delete event has no old ID');
      return;
    }

    // Check if this expense belongs to one of our groups
    final expenseBox = Hive.box<GroupExpense>('group_expenses');
    final existingExpense = expenseBox.get(oldId);

    if (existingExpense != null && _isMyGroup(existingExpense.groupId)) {
      debugPrint(
        '[GroupRealtime] Deleting expense $oldId from group ${existingExpense.groupId}',
      );
      _deleteExpenseLocally(oldId);
    } else {
      debugPrint(
        '[GroupRealtime] Expense $oldId not found or not in my groups, ignoring',
      );
    }
  }

  void _handleSplitChange(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.delete) {
      final oldId = payload.oldRecord['id'] as String?;
      if (oldId != null) {
        Hive.box<GroupExpenseSplit>('group_expense_splits').delete(oldId);
      }
      return;
    }
    final row = payload.newRecord;
    final id = row['id'] as String?;
    if (id == null) return;

    final isNowSettled = (row['is_settled'] as bool?) ?? false;
    final splitBox = Hive.box<GroupExpenseSplit>('group_expense_splits');
    final existingSplit = splitBox.get(id);
    final wasSettled = existingSplit?.isSettled ?? false;

    final split = GroupExpenseSplit(
      id: id,
      groupExpenseId: row['group_expense_id'] as String,
      userId: row['user_id'] as String,
      amount: (row['amount'] as num).toDouble(),
      isSettled: isNowSettled,
      settledAt: row['settled_at'] != null
          ? DateTime.parse(row['settled_at'] as String)
          : null,
      updatedAt: DateTime.parse(row['updated_at'] as String),
      syncStatus: 'synced',
    );
    splitBox.put(id, split);

    if (!wasSettled && isNowSettled) {
      _maybeRecordSettlementExpense(split);
    }
  }

  void _maybeRecordSettlementExpense(GroupExpenseSplit split) {
    final currentUserId = SupabaseService.currentUser?.id;
    debugPrint(
      '[GroupRealtime] _maybeRecordSettlementExpense called for split ${split.id}',
    );
    debugPrint(
      '[GroupRealtime] currentUserId: $currentUserId, split.userId: ${split.userId}, split.groupExpenseId: ${split.groupExpenseId}',
    );
    if (currentUserId == null) {
      debugPrint('[GroupRealtime] No current user, skipping');
      return;
    }

    final expenseBox = Hive.box<GroupExpense>('group_expenses');
    final groupExpense = expenseBox.get(split.groupExpenseId);
    debugPrint(
      '[GroupRealtime] groupExpense found: ${groupExpense != null}, paidByUserId: ${groupExpense?.paidByUserId}',
    );
    if (groupExpense == null) {
      debugPrint(
        '[GroupRealtime] Group expense not found, skipping settlement recording',
      );
      return;
    }

    final personalExpenseBox = Hive.box<Expense>('expenses');
    final now = DateTime.now();

    // Case 1: Current user is the debtor (they owed money and paid it back)
    debugPrint(
      '[GroupRealtime] Checking Case 1: split.userId(${split.userId}) == currentUserId($currentUserId) && paidByUserId(${groupExpense.paidByUserId}) != currentUserId($currentUserId)',
    );
    if (split.userId == currentUserId &&
        groupExpense.paidByUserId != currentUserId) {
      debugPrint('[GroupRealtime] Case 1 matched - debtor settlement');
      final settlementNote = '[Settlement] ${split.id}';
      final alreadyRecorded = personalExpenseBox.values.any(
        (e) => e.note == settlementNote,
      );
      if (alreadyRecorded) return;

      final categoryBox = Hive.box<Category>('categories');
      final expCat = categoryBox.values.firstWhere(
        (c) => c.effectiveType == 'expense',
        orElse: () => Category(
          id: 'unknown',
          name: 'Other',
          iconName: 'help_outline',
          color: 0xFF9E9E9E,
          isDefault: true,
          categoryType: 'expense',
        ),
      );

      final settleExpense = Expense(
        id: const Uuid().v4(),
        amount: split.amount,
        categoryId: expCat.id.isEmpty ? 'unknown' : expCat.id,
        date: split.settledAt ?? now,
        note: settlementNote,
        createdAt: now,
        groupId: groupExpense.groupId,
        groupExpenseId: split.groupExpenseId,
      );
      personalExpenseBox.put(settleExpense.id, settleExpense);
      debugPrint(
        '[GroupRealtime] Recorded debtor settlement expense: ${split.amount}',
      );
    }

    // Case 2: Current user is the creditor (they were owed money and got paid back)
    debugPrint(
      '[GroupRealtime] Checking Case 2: paidByUserId(${groupExpense.paidByUserId}) == currentUserId($currentUserId) && split.userId(${split.userId}) != currentUserId($currentUserId)',
    );
    if (groupExpense.paidByUserId == currentUserId &&
        split.userId != currentUserId) {
      debugPrint('[GroupRealtime] Case 2 matched - creditor settlement');
      final incomeNote = '[Settlement Received] ${split.id}';
      final incomeBox = Hive.box<Income>('incomes');
      final alreadyRecorded = incomeBox.values.any((i) => i.note == incomeNote);
      debugPrint('[GroupRealtime] Income already recorded: $alreadyRecorded');
      if (alreadyRecorded) {
        debugPrint('[GroupRealtime] Income already exists, skipping');
        return;
      }

      // Create proper Income record - creditor received money
      debugPrint('[GroupRealtime] Creating income with note: $incomeNote');
      final income = Income(
        id: const Uuid().v4(),
        amount: split.amount, // Positive amount for income
        source: 'Group Settlement', // Source/category for income
        date: split.settledAt ?? now,
        note: incomeNote,
        createdAt: now,
        groupExpenseId:
            split.groupExpenseId, // Key: link to expense for deletion
      );
      incomeBox.put(income.id, income);
      debugPrint(
        '[GroupRealtime] Recorded creditor settlement income: ${income.id} with note: $incomeNote, groupExpenseId: ${split.groupExpenseId}',
      );
    } else {
      debugPrint(
        '[GroupRealtime] Neither Case 1 nor Case 2 matched - user is not part of this settlement',
      );
    }
  }

  void _handleItemChange(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.delete) {
      final oldId = payload.oldRecord['id'] as String?;
      if (oldId != null) {
        Hive.box<GroupExpenseItem>('group_expense_items').delete(oldId);
      }
      return;
    }
    final row = payload.newRecord;
    final id = row['id'] as String?;
    if (id == null) return;
    final item = GroupExpenseItem(
      id: id,
      groupExpenseId: row['group_expense_id'] as String,
      description: row['description'] as String,
      amount: (row['amount'] as num).toDouble(),
      assignedToUserIds: List<String>.from(row['assigned_to_user_ids'] ?? []),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      syncStatus: 'synced',
    );
    Hive.box<GroupExpenseItem>('group_expense_items').put(id, item);
  }

  /// Delete an expense and all related local data when received via realtime
  void _deleteExpenseLocally(String expenseId) {
    debugPrint('[GroupRealtime] _deleteExpenseLocally called for $expenseId');
    final expenseBox = Hive.box<GroupExpense>('group_expenses');
    final splitBox = Hive.box<GroupExpenseSplit>('group_expense_splits');
    final itemBox = Hive.box<GroupExpenseItem>('group_expense_items');
    final personalExpenseBox = Hive.box<Expense>('expenses');
    final incomeBox = Hive.box<Income>('incomes');

    // Get splits before deleting to find related transactions
    final splits = splitBox.values
        .where((s) => s.groupExpenseId == expenseId)
        .toList();

    // Delete payer's personal expense (already uses groupExpenseId)
    final payerExpenses = personalExpenseBox.values
        .where((e) => e.groupExpenseId == expenseId)
        .toList();
    debugPrint(
      '[GroupRealtime] Found ${payerExpenses.length} payer expenses to delete',
    );
    for (final exp in payerExpenses) {
      personalExpenseBox.delete(exp.id);
      debugPrint('[GroupRealtime] Deleted payer expense ${exp.id}');
    }

    // Delete ALL settlement expenses for this expense (by groupExpenseId)
    final settlementExpensesByGroup = personalExpenseBox.values
        .where(
          (e) =>
              e.groupExpenseId == expenseId &&
              (e.note?.startsWith('[Settlement]') ?? false),
        )
        .toList();
    debugPrint(
      '[GroupRealtime] Found ${settlementExpensesByGroup.length} settlement expenses by groupExpenseId',
    );
    for (final exp in settlementExpensesByGroup) {
      personalExpenseBox.delete(exp.id);
      debugPrint('[GroupRealtime] Deleted settlement expense ${exp.id}');
    }

    // Delete ALL settlement income for this expense (by groupExpenseId)
    final settlementIncomesByGroup = incomeBox.values
        .where((i) => i.groupExpenseId == expenseId)
        .toList();
    debugPrint(
      '[GroupRealtime] Found ${settlementIncomesByGroup.length} settlement incomes by groupExpenseId',
    );
    for (final income in settlementIncomesByGroup) {
      incomeBox.delete(income.id);
      debugPrint('[GroupRealtime] Deleted settlement income ${income.id}');
    }

    // Also try split-based deletion (for device that created the expense where splits still exist)
    for (final split in splits) {
      // Delete debtor's settlement expense by note (backup method)
      final settlementNote = '[Settlement] ${split.id}';
      final settlementExpenses = personalExpenseBox.values
          .where((e) => e.note == settlementNote)
          .toList();
      for (final exp in settlementExpenses) {
        personalExpenseBox.delete(exp.id);
      }

      // Delete creditor's settlement income
      final incomeNote = '[Settlement Received] ${split.id}';
      debugPrint('[GroupRealtime] Looking for income with note: $incomeNote');
      final settlementIncomes = incomeBox.values.where((i) {
        debugPrint('[GroupRealtime] Checking income note: ${i.note}');
        return i.note == incomeNote;
      }).toList();
      debugPrint(
        '[GroupRealtime] Found ${settlementIncomes.length} settlement incomes to delete',
      );
      for (final income in settlementIncomes) {
        incomeBox.delete(income.id);
        debugPrint('[GroupRealtime] Deleted settlement income ${income.id}');
      }

      // Delete the split
      splitBox.delete(split.id);
    }

    // Delete items
    final items = itemBox.values
        .where((i) => i.groupExpenseId == expenseId)
        .toList();
    for (final item in items) {
      itemBox.delete(item.id);
    }

    // Delete the expense
    expenseBox.delete(expenseId);
    debugPrint(
      '[GroupRealtime] Deleted expense $expenseId and related data locally',
    );
  }
}
