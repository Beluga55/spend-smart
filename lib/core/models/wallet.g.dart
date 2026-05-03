// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WalletAdapter extends TypeAdapter<Wallet> {
  @override
  final int typeId = 7;

  @override
  Wallet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Wallet(
      id: fields[0] as String,
      name: fields[1] as String,
      iconName: fields[2] as String,
      color: fields[3] as int,
      type: fields[4] as String,
      isDefault: fields[5] as bool,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Wallet obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.iconName)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.isDefault)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
