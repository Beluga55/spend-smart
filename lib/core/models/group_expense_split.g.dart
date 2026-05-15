// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_expense_split.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupExpenseSplitAdapter extends TypeAdapter<GroupExpenseSplit> {
  @override
  final int typeId = 12;

  @override
  GroupExpenseSplit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupExpenseSplit(
      id: fields[0] as String,
      groupExpenseId: fields[1] as String,
      userId: fields[2] as String,
      amount: fields[3] as double,
      isSettled: fields[4] as bool,
      settledAt: fields[5] as DateTime?,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GroupExpenseSplit obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupExpenseId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.isSettled)
      ..writeByte(5)
      ..write(obj.settledAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupExpenseSplitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
