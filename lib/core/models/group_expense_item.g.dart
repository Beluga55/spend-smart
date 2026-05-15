// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_expense_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupExpenseItemAdapter extends TypeAdapter<GroupExpenseItem> {
  @override
  final int typeId = 13;

  @override
  GroupExpenseItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupExpenseItem(
      id: fields[0] as String,
      groupExpenseId: fields[1] as String,
      description: fields[2] as String,
      amount: fields[3] as double,
      assignedToUserIds: (fields[4] as List).cast<String>(),
      updatedAt: fields[5] as DateTime,
      syncStatus: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GroupExpenseItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupExpenseId)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.assignedToUserIds)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.syncStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupExpenseItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
