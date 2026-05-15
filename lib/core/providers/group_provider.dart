import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/models/group.dart';
import 'package:mobile_expense_tracker/core/models/group_member.dart';

final groupBoxProvider = Provider<Box<Group>>((ref) {
  return Hive.box<Group>('groups');
});

final groupMemberBoxProvider = Provider<Box<GroupMember>>((ref) {
  return Hive.box<GroupMember>('group_members');
});

final groupsProvider = StateNotifierProvider<GroupsNotifier, List<Group>>((ref) {
  final box = ref.watch(groupBoxProvider);
  return GroupsNotifier(box);
});

class GroupsNotifier extends StateNotifier<List<Group>> {
  final Box<Group> _box;

  GroupsNotifier(this._box) : super(_box.values.toList()) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() => state = _box.values.toList();

  Future<void> addGroup(Group group) async {
    await _box.put(group.id, group);
    _refresh();
  }

  Future<void> updateGroup(Group group) async {
    await _box.put(group.id, group);
    _refresh();
  }

  Future<void> deleteGroup(String id) async {
    await _box.delete(id);
    _refresh();
  }

  Group? getGroup(String id) => _box.get(id);
}

final groupMembersProvider = StateNotifierProvider.family<GroupMembersNotifier, List<GroupMember>, String>((ref, groupId) {
  final box = ref.watch(groupMemberBoxProvider);
  return GroupMembersNotifier(box, groupId);
});

class GroupMembersNotifier extends StateNotifier<List<GroupMember>> {
  final Box<GroupMember> _box;
  final String _groupId;

  GroupMembersNotifier(this._box, this._groupId)
      : super(_box.values.where((m) => m.groupId == _groupId && m.isActive).toList()) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() {
    state = _box.values.where((m) => m.groupId == _groupId && m.isActive).toList();
  }

  Future<void> addMember(GroupMember member) async {
    await _box.put(member.id, member);
    _refresh();
  }

  Future<void> removeMember(String memberId) async {
    final member = _box.get(memberId);
    if (member != null) {
      await _box.put(memberId, member.copyWith(isActive: false));
      _refresh();
    }
  }
}
