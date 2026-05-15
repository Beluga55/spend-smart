// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupExpenseAdapter extends TypeAdapter<GroupExpense> {
  @override
  final int typeId = 11;

  @override
  GroupExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupExpense(
      id: fields[0] as String,
      groupId: fields[1] as String,
      description: fields[2] as String,
      totalAmount: fields[3] as double,
      date: fields[4] as DateTime,
      paidByUserId: fields[5] as String,
      receiptImagePath: fields[6] as String?,
      syncStatus: fields[7] as String,
      supabaseId: fields[8] as String?,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GroupExpense obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.paidByUserId)
      ..writeByte(6)
      ..write(obj.receiptImagePath)
      ..writeByte(7)
      ..write(obj.syncStatus)
      ..writeByte(8)
      ..write(obj.supabaseId)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
