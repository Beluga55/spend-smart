// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringExpenseAdapter extends TypeAdapter<RecurringExpense> {
  @override
  final int typeId = 4;

  @override
  RecurringExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringExpense(
      id: fields[0] as String,
      amount: fields[1] as double,
      categoryId: fields[2] as String,
      note: fields[3] as String?,
      frequency: fields[4] as RecurringFrequency,
      startDate: fields[5] as DateTime,
      endDate: fields[6] as DateTime?,
      lastCreated: fields[7] as DateTime?,
      isActive: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringExpense obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.frequency)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.endDate)
      ..writeByte(7)
      ..write(obj.lastCreated)
      ..writeByte(8)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurringFrequencyAdapter extends TypeAdapter<RecurringFrequency> {
  @override
  final int typeId = 5;

  @override
  RecurringFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurringFrequency.daily;
      case 1:
        return RecurringFrequency.weekly;
      case 2:
        return RecurringFrequency.monthly;
      case 3:
        return RecurringFrequency.yearly;
      default:
        return RecurringFrequency.daily;
    }
  }

  @override
  void write(BinaryWriter writer, RecurringFrequency obj) {
    switch (obj) {
      case RecurringFrequency.daily:
        writer.writeByte(0);
        break;
      case RecurringFrequency.weekly:
        writer.writeByte(1);
        break;
      case RecurringFrequency.monthly:
        writer.writeByte(2);
        break;
      case RecurringFrequency.yearly:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
