import 'package:hive/hive.dart';

part 'group_member.g.dart';

@HiveType(typeId: 10)
class GroupMember extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String groupId;

  @HiveField(2)
  String? userId;

  @HiveField(3)
  String displayName;

  @HiveField(4)
  DateTime joinedAt;

  @HiveField(5)
  String role;

  @HiveField(6)
  bool isActive;

  @HiveField(7)
  DateTime updatedAt;

  GroupMember({
    required this.id,
    required this.groupId,
    this.userId,
    required this.displayName,
    required this.joinedAt,
    this.role = 'member',
    this.isActive = true,
    required this.updatedAt,
  });

  GroupMember copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? displayName,
    DateTime? joinedAt,
    String? role,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      joinedAt: joinedAt ?? this.joinedAt,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
