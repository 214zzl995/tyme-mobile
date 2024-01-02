// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_security_param.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClientSecurityParamAdapter extends TypeAdapter<ClientSecurityParam> {
  @override
  final int typeId = 2;

  @override
  ClientSecurityParam read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClientSecurityParam(
      filename: fields[0] as String,
      fileContent: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ClientSecurityParam obj) {
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
      other is ClientSecurityParamAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
