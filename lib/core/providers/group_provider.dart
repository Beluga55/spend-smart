import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/models/group.dart';
import 'package:mobile_expense_tracker/core/models/group_member.dart';
import 'package:mobile_expense_tracker/core/services/group_sync_service.dart';

final groupBoxProvider = Provider<Box<Group>>((ref) {
  return Hive.box<Group>('groups');
});

final groupMemberBoxProvider = Provider<Box<GroupMember>>((ref) {
  return Hive.box<GroupMember>('group_members');
});

final groupsProvider = StateNotifierProvider<GroupsNotifier, List<Group>>((
  ref,
) {
  final box = ref.watch(groupBoxProvider);
  final syncService = ref.watch(groupSyncServiceProvider);
  return GroupsNotifier(box, syncService);
});

class GroupsNotifier extends StateNotifier<List<Group>> {
  final Box<Group> _box;
  final GroupSyncService _syncService;

  GroupsNotifier(this._box, this._syncService) : super(_box.values.toList()) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() => state = _box.values.toList();

  Future<void> addGroup(Group group) async {
    await _box.put(group.id, group);
    _refresh();
    // Return sync future so callers can await if needed (e.g. before adding members)
    return _syncService.pushGroup(group);
  }

  Future<void> updateGroup(Group group) async {
    await _box.put(group.id, group);
    _refresh();
    return _syncService.pushGroup(group);
  }

  Future<void> deleteGroup(String id) async {
    await _box.delete(id);
    // Note: Supabase deletion is handled separately or via cascade
    _refresh();
  }

  Group? getGroup(String id) => _box.get(id);
}

final groupMembersProvider =
    StateNotifierProvider.family<
      GroupMembersNotifier,
      List<GroupMember>,
      String
    >((ref, groupId) {
      final box = ref.watch(groupMemberBoxProvider);
      final syncService = ref.watch(groupSyncServiceProvider);
      return GroupMembersNotifier(box, groupId, syncService);
    });

class GroupMembersNotifier extends StateNotifier<List<GroupMember>> {
  final Box<GroupMember> _box;
  final String _groupId;
  final GroupSyncService _syncService;

  GroupMembersNotifier(this._box, this._groupId, this._syncService)
    : super(
        _box.values.where((m) => m.groupId == _groupId && m.isActive).toList(),
      ) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() {
    state = _box.values
        .where((m) => m.groupId == _groupId && m.isActive)
        .toList();
  }

  Future<void> addMember(GroupMember member) async {
    debugPrint(
      '[GroupMembersNotifier] Adding member: ${member.displayName} to group: ${member.groupId}',
    );
    await _box.put(member.id, member);
    _refresh();
    debugPrint(
      '[GroupMembersNotifier] Local state updated, count: ${state.length}',
    );
    try {
      await _syncService.pushMember(member);
      debugPrint(
        '[GroupMembersNotifier] Sync succeeded for member: ${member.id}',
      );
    } catch (e) {
      debugPrint(
        '[GroupMembersNotifier] Sync failed for member: ${member.id}: $e',
      );
      rethrow;
    }
  }

  Future<void> removeMember(String memberId) async {
    final member = _box.get(memberId);
    if (member != null) {
      final updated = member.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );
      await _box.put(memberId, updated);
      _refresh();
      return _syncService.pushMember(updated);
    }
  }

  Future<void> updateMember(GroupMember member) async {
    await _box.put(member.id, member);
    _refresh();
    return _syncService.pushMember(member);
  }
}
