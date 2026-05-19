import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

class GroupSyncService {
  const GroupSyncService();

  // ------------------------------------------------------------------
  // PUSH
  // ------------------------------------------------------------------

  Future<void> _pushGroups() async {
    final box = Hive.box<Group>('groups');
    final pending = box.values.where((g) => g.syncStatus == 'pending').toList();

    for (final group in pending) {
      try {
        await SupabaseService.client.from('groups').upsert({
          'id': group.id,
          'name': group.name,
          'created_by': group.createdBy,
          'created_at': group.createdAt.toIso8601String(),
          'invite_code': group.inviteCode,
          'is_active': group.isActive,
          'updated_at': group.updatedAt.toIso8601String(),
        });
        await box.put(group.id, group.copyWith(syncStatus: 'synced'));
        debugPrint('[GroupSync] Pushed group: ${group.name}');
      } catch (e) {
        debugPrint('[GroupSync] Failed to push group ${group.id}: $e');
        await box.put(group.id, group.copyWith(syncStatus: 'error'));
      }
    }
  }

  Future<void> _pushMembers() async {
    final box = Hive.box<GroupMember>('group_members');
    final pending = box.values.where((m) => m.syncStatus == 'pending').toList();

    for (final member in pending) {
      try {
        await SupabaseService.client.from('group_members').upsert({
          'id': member.id,
          'group_id': member.groupId,
          'user_id': member.userId,
          'display_name': member.displayName,
          'joined_at': member.joinedAt.toIso8601String(),
          'role': member.role,
          'is_active': member.isActive,
          'updated_at': member.updatedAt.toIso8601String(),
        });
        await box.put(member.id, member.copyWith(syncStatus: 'synced'));
        debugPrint('[GroupSync] Pushed member: ${member.displayName}');
      } catch (e) {
        debugPrint('[GroupSync] Failed to push member ${member.id}: $e');
        await box.put(member.id, member.copyWith(syncStatus: 'error'));
      }
    }
  }

  Future<void> _pushExpenses() async {
    final box = Hive.box<GroupExpense>('group_expenses');
    final pending = box.values.where((e) => e.syncStatus == 'pending').toList();

    for (final expense in pending) {
      try {
        await SupabaseService.client.from('group_expenses').upsert({
          'id': expense.id,
          'group_id': expense.groupId,
          'description': expense.description,
          'total_amount': expense.totalAmount,
          'date': expense.date.toIso8601String().split('T').first,
          'paid_by_user_id': expense.paidByUserId,
          'receipt_image_path': expense.receiptImagePath,
          'created_at': expense.createdAt.toIso8601String(),
          'updated_at': expense.updatedAt.toIso8601String(),
        });
        await box.put(expense.id, expense.copyWith(syncStatus: 'synced'));
        debugPrint('[GroupSync] Pushed expense: ${expense.description}');
      } catch (e) {
        debugPrint('[GroupSync] Failed to push expense ${expense.id}: $e');
        await box.put(expense.id, expense.copyWith(syncStatus: 'error'));
      }
    }
  }

  Future<void> _pushSplits() async {
    final box = Hive.box<GroupExpenseSplit>('group_expense_splits');
    final pending = box.values.where((s) => s.syncStatus == 'pending').toList();

    for (final split in pending) {
      try {
        await SupabaseService.client.from('group_expense_splits').upsert({
          'id': split.id,
          'group_expense_id': split.groupExpenseId,
          'user_id': split.userId,
          'amount': split.amount,
          'is_settled': split.isSettled,
          'settled_at': split.settledAt?.toIso8601String(),
          'updated_at': split.updatedAt.toIso8601String(),
        });
        await box.put(split.id, split.copyWith(syncStatus: 'synced'));
        debugPrint('[GroupSync] Pushed split: ${split.id}');
      } catch (e) {
        debugPrint('[GroupSync] Failed to push split ${split.id}: $e');
        await box.put(split.id, split.copyWith(syncStatus: 'error'));
      }
    }
  }

  Future<void> _pushItems() async {
    final box = Hive.box<GroupExpenseItem>('group_expense_items');
    final pending = box.values.where((i) => i.syncStatus == 'pending').toList();

    for (final item in pending) {
      try {
        await SupabaseService.client.from('group_expense_items').upsert({
          'id': item.id,
          'group_expense_id': item.groupExpenseId,
          'description': item.description,
          'amount': item.amount,
          'assigned_to_user_ids': item.assignedToUserIds,
          'updated_at': item.updatedAt.toIso8601String(),
        });
        await box.put(item.id, item.copyWith(syncStatus: 'synced'));
        debugPrint('[GroupSync] Pushed item: ${item.description}');
      } catch (e) {
        debugPrint('[GroupSync] Failed to push item ${item.id}: $e');
        await box.put(item.id, item.copyWith(syncStatus: 'error'));
      }
    }
  }

  // ------------------------------------------------------------------
  // PULL
  // ------------------------------------------------------------------

  Future<void> _pullGroups() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    // Only pull groups the user is a member of
    final memberRows = await SupabaseService.client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId)
        .eq('is_active', true);
    final myGroupIds = memberRows
        .map<String>((r) => r['group_id'] as String)
        .toList();

    if (myGroupIds.isEmpty) return;

    final groupBox = Hive.box<Group>('groups');

    for (final groupId in myGroupIds) {
      try {
        final rows = await SupabaseService.client
            .from('groups')
            .select()
            .eq('id', groupId)
            .limit(1);
        if (rows.isNotEmpty) {
          final row = rows.first;
          final existing = groupBox.get(groupId);
          final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);
          // Skip only if local copy is already up-to-date
          if (existing != null &&
              !existing.updatedAt.isBefore(remoteUpdatedAt)) {
            continue;
          }
          final group = Group(
            id: row['id'],
            name: row['name'],
            createdBy: row['created_by'],
            createdAt: DateTime.parse(row['created_at']),
            inviteCode: row['invite_code'],
            isActive: row['is_active'] ?? true,
            updatedAt: remoteUpdatedAt,
            syncStatus: 'synced',
          );
          await groupBox.put(group.id, group);
          debugPrint('[GroupSync] Pulled updated group: ${group.name}');
        }
      } catch (e) {
        debugPrint('[GroupSync] Failed to pull group $groupId: $e');
      }
    }
  }

  Future<void> _pullMembers() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    // Get the user's group IDs from local Hive
    final groupBox = Hive.box<Group>('groups');
    final myGroupIds = groupBox.keys.toList().cast<String>();
    if (myGroupIds.isEmpty) return;

    final memberBox = Hive.box<GroupMember>('group_members');

    for (final groupId in myGroupIds) {
      try {
        final rows = await SupabaseService.client
            .from('group_members')
            .select()
            .eq('group_id', groupId);
        for (final row in rows) {
          final member = GroupMember(
            id: row['id'],
            groupId: row['group_id'],
            userId: row['user_id'],
            displayName: row['display_name'],
            joinedAt: DateTime.parse(row['joined_at']),
            role: row['role'] ?? 'member',
            isActive: row['is_active'] ?? true,
            updatedAt: DateTime.parse(row['updated_at']),
          );
          await memberBox.put(member.id, member);
        }
      } catch (e) {
        debugPrint('[GroupSync] Failed to pull members for group $groupId: $e');
      }
    }
  }

  Future<void> _pullExpenses() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final groupBox = Hive.box<Group>('groups');
    final myGroupIds = groupBox.keys.toList().cast<String>();
    if (myGroupIds.isEmpty) return;

    final expenseBox = Hive.box<GroupExpense>('group_expenses');

    for (final groupId in myGroupIds) {
      try {
        final rows = await SupabaseService.client
            .from('group_expenses')
            .select()
            .eq('group_id', groupId);
        for (final row in rows) {
          final expense = GroupExpense(
            id: row['id'],
            groupId: row['group_id'],
            description: row['description'],
            totalAmount: (row['total_amount'] as num).toDouble(),
            date: DateTime.parse(row['date']),
            paidByUserId: row['paid_by_user_id'],
            receiptImagePath: row['receipt_image_path'],
            syncStatus: 'synced',
            createdAt: DateTime.parse(row['created_at']),
            updatedAt: DateTime.parse(row['updated_at']),
          );
          await expenseBox.put(expense.id, expense);
        }
      } catch (e) {
        debugPrint(
          '[GroupSync] Failed to pull expenses for group $groupId: $e',
        );
      }
    }
  }

  Future<void> _pullSplits() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    // Get all expense IDs for the user's groups
    final expenseBox = Hive.box<GroupExpense>('group_expenses');
    final expenseIds = expenseBox.values.map((e) => e.id).toList();
    if (expenseIds.isEmpty) return;

    final splitBox = Hive.box<GroupExpenseSplit>('group_expense_splits');

    for (final expenseId in expenseIds) {
      try {
        final rows = await SupabaseService.client
            .from('group_expense_splits')
            .select()
            .eq('group_expense_id', expenseId);
        for (final row in rows) {
          final isNowSettled = (row['is_settled'] as bool?) ?? false;
          final existingSplit = splitBox.get(row['id'] as String);
          final wasSettled = existingSplit?.isSettled ?? false;

          final split = GroupExpenseSplit(
            id: row['id'],
            groupExpenseId: row['group_expense_id'],
            userId: row['user_id'],
            amount: (row['amount'] as num).toDouble(),
            isSettled: isNowSettled,
            settledAt: row['settled_at'] != null
                ? DateTime.parse(row['settled_at'])
                : null,
            updatedAt: DateTime.parse(row['updated_at']),
          );
          await splitBox.put(split.id, split);

          // Detect debtor settlement: was unsettled locally, now settled,
          // and this split belongs to the current user as the debtor.
          if (!wasSettled && isNowSettled) {
            _maybeRecordSettlementExpense(split, expenseBox, userId);
          }
        }
      } catch (e) {
        debugPrint(
          '[GroupSync] Failed to pull splits for expense $expenseId: $e',
        );
      }
    }
  }

  /// Records settlement transactions for both debtor and creditor.
  void _maybeRecordSettlementExpense(
    GroupExpenseSplit split,
    Box<GroupExpense> expenseBox,
    String currentUserId,
  ) {
    final groupExpense = expenseBox.get(split.groupExpenseId);
    if (groupExpense == null) return;

    final personalExpenseBox = Hive.box<Expense>('expenses');
    final now = DateTime.now();

    // Case 1: Current user is the debtor (they owed money and paid it back)
    if (split.userId == currentUserId && groupExpense.paidByUserId != currentUserId) {
      final settlementNote = '[Settlement] ${split.id}';
      final alreadyRecorded = personalExpenseBox.values.any((e) => e.note == settlementNote);
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
      debugPrint('[GroupSync] Recorded debtor settlement: ${split.amount}');
    }

    // Case 2: Current user is the creditor (they were owed money and got paid back)
    if (groupExpense.paidByUserId == currentUserId && split.userId != currentUserId) {
      final incomeNote = '[Settlement Received] ${split.id}';
      final incomeBox = Hive.box<Income>('incomes');
      final alreadyRecorded = incomeBox.values.any((i) => i.note == incomeNote);
      if (alreadyRecorded) return;

      // Create proper Income record - creditor received money
      final income = Income(
        id: const Uuid().v4(),
        amount: split.amount, // Positive amount for income
        source: 'Group Settlement',
        date: split.settledAt ?? now,
        note: incomeNote,
        createdAt: now,
      );
      incomeBox.put(income.id, income);
      debugPrint('[GroupSync] Recorded creditor settlement income: ${split.amount}');
    }
  }

  Future<void> _pullItems() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final expenseBox = Hive.box<GroupExpense>('group_expenses');
    final expenseIds = expenseBox.values.map((e) => e.id).toList();
    if (expenseIds.isEmpty) return;

    final itemBox = Hive.box<GroupExpenseItem>('group_expense_items');

    for (final expenseId in expenseIds) {
      try {
        final rows = await SupabaseService.client
            .from('group_expense_items')
            .select()
            .eq('group_expense_id', expenseId);
        for (final row in rows) {
          final item = GroupExpenseItem(
            id: row['id'],
            groupExpenseId: row['group_expense_id'],
            description: row['description'],
            amount: (row['amount'] as num).toDouble(),
            assignedToUserIds: List<String>.from(
              row['assigned_to_user_ids'] ?? [],
            ),
            updatedAt: DateTime.parse(row['updated_at']),
          );
          await itemBox.put(item.id, item);
        }
      } catch (e) {
        debugPrint(
          '[GroupSync] Failed to pull items for expense $expenseId: $e',
        );
      }
    }
  }

  // ------------------------------------------------------------------
  // PUBLIC API
  // ------------------------------------------------------------------

  /// Pulls all data for a specific group (metadata, members, expenses, splits, items).
  /// Ideal for calling immediately after joining a group.
  Future<void> pullGroupHistory(String groupId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    debugPrint('[GroupSync] Pulling history for group: $groupId');

    // 1. Pull/Update Group Metadata
    await _pullSpecificGroup(groupId);

    // 2. Pull Members
    await _pullMembersForGroup(groupId);

    // 3. Pull Expenses and their details
    try {
      final rows = await SupabaseService.client
          .from('group_expenses')
          .select()
          .eq('group_id', groupId);
      
      final expenseBox = Hive.box<GroupExpense>('group_expenses');
      for (final row in rows) {
        final expense = GroupExpense(
          id: row['id'],
          groupId: row['group_id'],
          description: row['description'],
          totalAmount: (row['total_amount'] as num).toDouble(),
          date: DateTime.parse(row['date']),
          paidByUserId: row['paid_by_user_id'],
          receiptImagePath: row['receipt_image_path'],
          syncStatus: 'synced',
          createdAt: DateTime.parse(row['created_at']),
          updatedAt: DateTime.parse(row['updated_at']),
        );
        await expenseBox.put(expense.id, expense);

        // Pull splits and items for this specific expense
        await _pullSplitsForExpense(expense.id, userId);
        await _pullItemsForExpense(expense.id);
      }
    } catch (e) {
      debugPrint('[GroupSync] Failed to pull expenses for group $groupId: $e');
    }
    
    debugPrint('[GroupSync] Finished pulling history for group: $groupId');
  }

  Future<void> _pullSpecificGroup(String groupId) async {
    try {
      final row = await SupabaseService.client
          .from('groups')
          .select()
          .eq('id', groupId)
          .maybeSingle();
      
      if (row != null) {
        final groupBox = Hive.box<Group>('groups');
        final group = Group(
          id: row['id'],
          name: row['name'],
          createdBy: row['created_by'],
          createdAt: DateTime.parse(row['created_at']),
          inviteCode: row['invite_code'],
          isActive: row['is_active'] ?? true,
          updatedAt: DateTime.parse(row['updated_at']),
          syncStatus: 'synced',
        );
        await groupBox.put(group.id, group);
      }
    } catch (e) {
      debugPrint('[GroupSync] Failed to pull group $groupId: $e');
    }
  }

  Future<void> _pullMembersForGroup(String groupId) async {
    try {
      final rows = await SupabaseService.client
          .from('group_members')
          .select()
          .eq('group_id', groupId);
      
      final memberBox = Hive.box<GroupMember>('group_members');
      for (final row in rows) {
        final member = GroupMember(
          id: row['id'],
          groupId: row['group_id'],
          userId: row['user_id'],
          displayName: row['display_name'],
          joinedAt: DateTime.parse(row['joined_at']),
          role: row['role'] ?? 'member',
          isActive: row['is_active'] ?? true,
          updatedAt: DateTime.parse(row['updated_at']),
          syncStatus: 'synced',
        );
        await memberBox.put(member.id, member);
      }
    } catch (e) {
      debugPrint('[GroupSync] Failed to pull members for group $groupId: $e');
    }
  }

  Future<void> _pullSplitsForExpense(String expenseId, String currentUserId) async {
    try {
      final rows = await SupabaseService.client
          .from('group_expense_splits')
          .select()
          .eq('group_expense_id', expenseId);
      
      final splitBox = Hive.box<GroupExpenseSplit>('group_expense_splits');
      final expenseBox = Hive.box<GroupExpense>('group_expenses');

      for (final row in rows) {
        final isNowSettled = (row['is_settled'] as bool?) ?? false;
        final existingSplit = splitBox.get(row['id'] as String);
        final wasSettled = existingSplit?.isSettled ?? false;

        final split = GroupExpenseSplit(
          id: row['id'],
          groupExpenseId: row['group_expense_id'],
          userId: row['user_id'],
          amount: (row['amount'] as num).toDouble(),
          isSettled: isNowSettled,
          settledAt: row['settled_at'] != null
              ? DateTime.parse(row['settled_at'])
              : null,
          updatedAt: DateTime.parse(row['updated_at']),
          syncStatus: 'synced',
        );
        await splitBox.put(split.id, split);

        if (!wasSettled && isNowSettled) {
          _maybeRecordSettlementExpense(split, expenseBox, currentUserId);
        }
      }
    } catch (e) {
      debugPrint('[GroupSync] Failed to pull splits for expense $expenseId: $e');
    }
  }

  Future<void> _pullItemsForExpense(String expenseId) async {
    try {
      final rows = await SupabaseService.client
          .from('group_expense_items')
          .select()
          .eq('group_expense_id', expenseId);
      
      final itemBox = Hive.box<GroupExpenseItem>('group_expense_items');
      for (final row in rows) {
        final item = GroupExpenseItem(
          id: row['id'],
          groupExpenseId: row['group_expense_id'],
          description: row['description'],
          amount: (row['amount'] as num).toDouble(),
          assignedToUserIds: List<String>.from(row['assigned_to_user_ids'] ?? []),
          updatedAt: DateTime.parse(row['updated_at']),
          syncStatus: 'synced',
        );
        await itemBox.put(item.id, item);
      }
    } catch (e) {
      debugPrint('[GroupSync] Failed to pull items for expense $expenseId: $e');
    }
  }

  Future<void> pushGroup(Group group) async {
    try {
      await SupabaseService.client.from('groups').upsert({
        'id': group.id,
        'name': group.name,
        'created_by': group.createdBy,
        'created_at': group.createdAt.toIso8601String(),
        'invite_code': group.inviteCode,
        'is_active': group.isActive,
        'updated_at': group.updatedAt.toIso8601String(),
      });
      final box = Hive.box<Group>('groups');
      await box.put(group.id, group.copyWith(syncStatus: 'synced'));
      debugPrint('[GroupSync] Pushed group: ${group.name}');
    } catch (e) {
      debugPrint('[GroupSync] Failed to push group ${group.id}: $e');
      final box = Hive.box<Group>('groups');
      await box.put(group.id, group.copyWith(syncStatus: 'error'));
      rethrow;
    }
  }

  Future<void> pushMember(GroupMember member) async {
    try {
      await SupabaseService.client.from('group_members').upsert({
        'id': member.id,
        'group_id': member.groupId,
        'user_id': member.userId,
        'display_name': member.displayName,
        'joined_at': member.joinedAt.toIso8601String(),
        'role': member.role,
        'is_active': member.isActive,
        'updated_at': member.updatedAt.toIso8601String(),
      });
      final box = Hive.box<GroupMember>('group_members');
      await box.put(member.id, member.copyWith(syncStatus: 'synced'));
      debugPrint('[GroupSync] Pushed member: ${member.displayName}');
    } catch (e) {
      debugPrint('[GroupSync] Failed to push member ${member.id}: $e');
      final box = Hive.box<GroupMember>('group_members');
      await box.put(member.id, member.copyWith(syncStatus: 'error'));
      rethrow;
    }
  }

  Future<void> pushExpense(GroupExpense expense) async {
    try {
      await SupabaseService.client.from('group_expenses').upsert({
        'id': expense.id,
        'group_id': expense.groupId,
        'description': expense.description,
        'total_amount': expense.totalAmount,
        'date': expense.date.toIso8601String().split('T').first,
        'paid_by_user_id': expense.paidByUserId,
        'receipt_image_path': expense.receiptImagePath,
        'created_at': expense.createdAt.toIso8601String(),
        'updated_at': expense.updatedAt.toIso8601String(),
      });
      final box = Hive.box<GroupExpense>('group_expenses');
      await box.put(expense.id, expense.copyWith(syncStatus: 'synced'));
      debugPrint('[GroupSync] Pushed expense: ${expense.description}');
    } catch (e) {
      debugPrint('[GroupSync] Failed to push expense ${expense.id}: $e');
      final box = Hive.box<GroupExpense>('group_expenses');
      await box.put(expense.id, expense.copyWith(syncStatus: 'error'));
      rethrow;
    }
  }

  Future<void> pushSplit(GroupExpenseSplit split) async {
    try {
      await SupabaseService.client.from('group_expense_splits').upsert({
        'id': split.id,
        'group_expense_id': split.groupExpenseId,
        'user_id': split.userId,
        'amount': split.amount,
        'is_settled': split.isSettled,
        'settled_at': split.settledAt?.toIso8601String(),
        'updated_at': split.updatedAt.toIso8601String(),
      });
      final box = Hive.box<GroupExpenseSplit>('group_expense_splits');
      await box.put(split.id, split.copyWith(syncStatus: 'synced'));
      debugPrint('[GroupSync] Pushed split: ${split.id}');
    } catch (e) {
      debugPrint('[GroupSync] Failed to push split ${split.id}: $e');
      final box = Hive.box<GroupExpenseSplit>('group_expense_splits');
      await box.put(split.id, split.copyWith(syncStatus: 'error'));
      rethrow;
    }
  }

  Future<void> pushItem(GroupExpenseItem item) async {
    try {
      await SupabaseService.client.from('group_expense_items').upsert({
        'id': item.id,
        'group_expense_id': item.groupExpenseId,
        'description': item.description,
        'amount': item.amount,
        'assigned_to_user_ids': item.assignedToUserIds,
        'updated_at': item.updatedAt.toIso8601String(),
      });
      final box = Hive.box<GroupExpenseItem>('group_expense_items');
      await box.put(item.id, item.copyWith(syncStatus: 'synced'));
      debugPrint('[GroupSync] Pushed item: ${item.description}');
    } catch (e) {
      debugPrint('[GroupSync] Failed to push item ${item.id}: $e');
      final box = Hive.box<GroupExpenseItem>('group_expense_items');
      await box.put(item.id, item.copyWith(syncStatus: 'error'));
      rethrow;
    }
  }

  /// Delete a group expense (and its splits + items + related transactions) from Supabase and Hive.
  Future<void> deleteExpense(String expenseId) async {
    // Get the splits before deleting to find related settlement transactions
    final splitBox = Hive.box<GroupExpenseSplit>('group_expense_splits');
    final splits = splitBox.values.where((s) => s.groupExpenseId == expenseId).toList();

    // Delete from Supabase (cascade handles splits + items in DB if set up,
    // but we also clean them explicitly for safety).
    try {
      await SupabaseService.client
          .from('group_expense_splits')
          .delete()
          .eq('group_expense_id', expenseId);
      await SupabaseService.client
          .from('group_expense_items')
          .delete()
          .eq('group_expense_id', expenseId);
      await SupabaseService.client
          .from('group_expenses')
          .delete()
          .eq('id', expenseId);
      debugPrint('[GroupSync] Deleted expense $expenseId from Supabase');
    } catch (e) {
      debugPrint('[GroupSync] Failed to delete expense $expenseId from Supabase: $e');
    }

    // Delete related personal transactions
    await _deleteRelatedTransactions(expenseId, splits);

    // Delete from local Hive boxes
    final itemBox = Hive.box<GroupExpenseItem>('group_expense_items');
    final itemIds = itemBox.values
        .where((i) => i.groupExpenseId == expenseId)
        .map((i) => i.id)
        .toList();
    for (final id in itemIds) {
      await itemBox.delete(id);
    }

    for (final split in splits) {
      await splitBox.delete(split.id);
    }

    await Hive.box<GroupExpense>('group_expenses').delete(expenseId);
    debugPrint('[GroupSync] Deleted expense $expenseId and related transactions from Hive');
  }

  /// Delete personal transactions related to a group expense:
  /// 1. Payer's personal expense
  /// 2. Settlement expenses/income for all splits
  Future<void> _deleteRelatedTransactions(String expenseId, List<GroupExpenseSplit> splits) async {
    final expenseBox = Hive.box<Expense>('expenses');
    final incomeBox = Hive.box<Income>('incomes');

    // Delete payer's personal expense
    final payerExpenses = expenseBox.values.where((e) => e.groupExpenseId == expenseId).toList();
    for (final exp in payerExpenses) {
      await expenseBox.delete(exp.id);
      debugPrint('[GroupSync] Deleted payer expense ${exp.id}');
    }

    // Delete ALL settlement expenses for this expense (by groupExpenseId)
    final settlementExpensesByGroup = expenseBox.values.where((e) => e.groupExpenseId == expenseId && (e.note?.startsWith('[Settlement]') ?? false)).toList();
    debugPrint('[GroupSync] Found ${settlementExpensesByGroup.length} settlement expenses by groupExpenseId');
    for (final exp in settlementExpensesByGroup) {
      await expenseBox.delete(exp.id);
      debugPrint('[GroupSync] Deleted settlement expense ${exp.id}');
    }

    // Delete ALL settlement income for this expense (by groupExpenseId)
    final settlementIncomesByGroup = incomeBox.values.where((i) => i.groupExpenseId == expenseId).toList();
    debugPrint('[GroupSync] Found ${settlementIncomesByGroup.length} settlement incomes by groupExpenseId');
    for (final income in settlementIncomesByGroup) {
      await incomeBox.delete(income.id);
      debugPrint('[GroupSync] Deleted settlement income ${income.id}');
    }

    // Also try split-based deletion (backup method)
    for (final split in splits) {
      // Delete debtor's settlement expense by note
      final settlementNote = '[Settlement] ${split.id}';
      final settlementExpenses = expenseBox.values.where((e) => e.note == settlementNote).toList();
      for (final exp in settlementExpenses) {
        await expenseBox.delete(exp.id);
        debugPrint('[GroupSync] Deleted settlement expense by note ${exp.id}');
      }

      // Delete creditor's settlement income by note
      final incomeNote = '[Settlement Received] ${split.id}';
      final settlementIncomes = incomeBox.values.where((i) => i.note == incomeNote).toList();
      for (final income in settlementIncomes) {
        await incomeBox.delete(income.id);
        debugPrint('[GroupSync] Deleted settlement income by note ${income.id}');
      }
    }
  }

  Future<void> syncAll() async {
    await _pushGroups();
    await _pushMembers();
    await _pushExpenses();
    await _pushSplits();
    await _pushItems();

    await _pullGroups();
    await _pullMembers();
    await _pullExpenses();
    await _pullSplits();
    await _pullItems();

    final settings = Hive.box('settings');
    await settings.put('groupSyncLastAt', DateTime.now().toIso8601String());
  }
}

final groupSyncServiceProvider = Provider<GroupSyncService>((ref) {
  return const GroupSyncService();
});
