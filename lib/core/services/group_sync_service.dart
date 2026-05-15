import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/models/group.dart';
import 'package:mobile_expense_tracker/core/models/group_member.dart';
import 'package:mobile_expense_tracker/core/models/group_expense.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_split.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_item.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';

class GroupSyncService {
  const GroupSyncService();

  // ------------------------------------------------------------------
  // PUSH
  // ------------------------------------------------------------------

  Future<void> _pushGroups() async {
    final box = Hive.box<Group>('groups');
    final pending = box.values.where((g) => g.syncStatus == 'pending');

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
      } catch (e) {
        await box.put(group.id, group.copyWith(syncStatus: 'error'));
      }
    }
  }

  Future<void> _pushMembers() async {
    final box = Hive.box<GroupMember>('group_members');
    final pending = box.values.where((m) => m.syncStatus == 'pending');

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
      } catch (e) {
        await box.put(member.id, member.copyWith(syncStatus: 'error'));
      }
    }
  }

  Future<void> _pushExpenses() async {
    final box = Hive.box<GroupExpense>('group_expenses');
    final pending = box.values.where((e) => e.syncStatus == 'pending');

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
      } catch (e) {
        await box.put(expense.id, expense.copyWith(syncStatus: 'error'));
      }
    }
  }

  Future<void> _pushSplits() async {
    final box = Hive.box<GroupExpenseSplit>('group_expense_splits');
    final pending = box.values.where((s) => s.syncStatus == 'pending');

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
      } catch (e) {
        await box.put(split.id, split.copyWith(syncStatus: 'error'));
      }
    }
  }

  Future<void> _pushItems() async {
    final box = Hive.box<GroupExpenseItem>('group_expense_items');
    final pending = box.values.where((i) => i.syncStatus == 'pending');

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
      } catch (e) {
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

    final settings = Hive.box('settings');
    final lastSync = settings.get('groupSyncLastAt') as String?;

    var query = SupabaseService.client
        .from('groups')
        .select()
        .eq('is_active', true);

    if (lastSync != null) {
      query = query.gt('updated_at', lastSync);
    }

    final rows = await query;
    final box = Hive.box<Group>('groups');

    for (final row in rows) {
      final group = Group(
        id: row['id'],
        name: row['name'],
        createdBy: row['created_by'],
        createdAt: DateTime.parse(row['created_at']),
        inviteCode: row['invite_code'],
        isActive: row['is_active'] ?? true,
        updatedAt: DateTime.parse(row['updated_at']),
      );
      await box.put(group.id, group);
    }
  }

  Future<void> _pullMembers() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final settings = Hive.box('settings');
    final lastSync = settings.get('groupSyncLastAt') as String?;

    var query = SupabaseService.client.from('group_members').select();
    if (lastSync != null) {
      query = query.gt('updated_at', lastSync);
    }

    final rows = await query;
    final box = Hive.box<GroupMember>('group_members');

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
      await box.put(member.id, member);
    }
  }

  Future<void> _pullExpenses() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final settings = Hive.box('settings');
    final lastSync = settings.get('groupSyncLastAt') as String?;

    var query = SupabaseService.client.from('group_expenses').select();
    if (lastSync != null) {
      query = query.gt('updated_at', lastSync);
    }

    final rows = await query;
    final box = Hive.box<GroupExpense>('group_expenses');

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
      await box.put(expense.id, expense);
    }
  }

  Future<void> _pullSplits() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final settings = Hive.box('settings');
    final lastSync = settings.get('groupSyncLastAt') as String?;

    var query = SupabaseService.client.from('group_expense_splits').select();
    if (lastSync != null) {
      query = query.gt('updated_at', lastSync);
    }

    final rows = await query;
    final box = Hive.box<GroupExpenseSplit>('group_expense_splits');

    for (final row in rows) {
      final split = GroupExpenseSplit(
        id: row['id'],
        groupExpenseId: row['group_expense_id'],
        userId: row['user_id'],
        amount: (row['amount'] as num).toDouble(),
        isSettled: row['is_settled'] ?? false,
        settledAt: row['settled_at'] != null ? DateTime.parse(row['settled_at']) : null,
        updatedAt: DateTime.parse(row['updated_at']),
      );
      await box.put(split.id, split);
    }
  }

  Future<void> _pullItems() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final settings = Hive.box('settings');
    final lastSync = settings.get('groupSyncLastAt') as String?;

    var query = SupabaseService.client.from('group_expense_items').select();
    if (lastSync != null) {
      query = query.gt('updated_at', lastSync);
    }

    final rows = await query;
    final box = Hive.box<GroupExpenseItem>('group_expense_items');

    for (final row in rows) {
      final item = GroupExpenseItem(
        id: row['id'],
        groupExpenseId: row['group_expense_id'],
        description: row['description'],
        amount: (row['amount'] as num).toDouble(),
        assignedToUserIds: List<String>.from(row['assigned_to_user_ids'] ?? []),
        updatedAt: DateTime.parse(row['updated_at']),
      );
      await box.put(item.id, item);
    }
  }

  // ------------------------------------------------------------------
  // PUBLIC API
  // ------------------------------------------------------------------

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
