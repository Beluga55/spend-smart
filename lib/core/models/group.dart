import 'package:hive/hive.dart';

part 'group.g.dart';

@HiveType(typeId: 9)
class Group extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String createdBy;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  String inviteCode;

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  DateTime updatedAt;

  Group({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.inviteCode,
    this.isActive = true,
    required this.updatedAt,
  });

  Group copyWith({
    String? id,
    String? name,
    String? createdBy,
    DateTime? createdAt,
    String? inviteCode,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      inviteCode: inviteCode ?? this.inviteCode,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
