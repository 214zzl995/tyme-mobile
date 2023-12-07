// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clint_security_param.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClintSecurityParamAdapter extends TypeAdapter<ClintSecurityParam> {
  @override
  final int typeId = 2;

  @override
  ClintSecurityParam read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClintSecurityParam(
      filename: fields[0] as String,
      fileContent: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ClintSecurityParam obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.filename)
      ..writeByte(1)
      ..write(obj.fileContent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClintSecurityParamAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
