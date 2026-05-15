// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupMemberAdapter extends TypeAdapter<GroupMember> {
  @override
  final int typeId = 10;

  @override
  GroupMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupMember(
      id: fields[0] as String,
      groupId: fields[1] as String,
      userId: fields[2] as String?,
      displayName: fields[3] as String,
      joinedAt: fields[4] as DateTime,
      role: fields[5] as String,
      isActive: fields[6] as bool,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GroupMember obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.displayName)
      ..writeByte(4)
      ..write(obj.joinedAt)
      ..writeByte(5)
      ..write(obj.role)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
