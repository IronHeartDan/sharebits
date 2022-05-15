// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BitsContactAdapter extends TypeAdapter<BitsContact> {
  @override
  final int typeId = 0;

  @override
  BitsContact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BitsContact(
      fields[0] as String,
      fields[1] as String,
    )..isAccount = fields[2] as bool;
  }

  @override
  void write(BinaryWriter writer, BitsContact obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.phone)
      ..writeByte(2)
      ..write(obj.isAccount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BitsContactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
