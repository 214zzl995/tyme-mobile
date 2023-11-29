// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clint_param.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClintParamAdapter extends TypeAdapter<ClintParam> {
  @override
  final int typeId = 1;

  @override
  ClintParam read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClintParam()
      ..broker = fields[0] as String
      ..port = fields[1] as int
      ..clintId = fields[2] as String
      ..username = fields[3] as String
      ..password = fields[4] as String;
  }

  @override
  void write(BinaryWriter writer, ClintParam obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.broker)
      ..writeByte(1)
      ..write(obj.port)
      ..writeByte(2)
      ..write(obj.clintId)
      ..writeByte(3)
      ..write(obj.username)
      ..writeByte(4)
      ..write(obj.password);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClintParamAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
