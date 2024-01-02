// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_param.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClientParamAdapter extends TypeAdapter<ClientParam> {
  @override
  final int typeId = 1;

  @override
  ClientParam read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClientParam(
      fields[0] as String,
      fields[1] as int,
      fields[2] as String,
      fields[3] as String?,
      fields[4] as String?,
      fields[5] as ClientSecurityParam?,
      (fields[6] as List).cast<SubscribeTopic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ClientParam obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.broker)
      ..writeByte(1)
      ..write(obj.port)
      ..writeByte(2)
      ..write(obj.clientId)
      ..writeByte(3)
      ..write(obj.username)
      ..writeByte(4)
      ..write(obj.password)
      ..writeByte(5)
      ..write(obj.securityParam)
      ..writeByte(6)
      ..write(obj.subscribeTopics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientParamAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubscribeTopicAdapter extends TypeAdapter<SubscribeTopic> {
  @override
  final int typeId = 7;

  @override
  SubscribeTopic read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscribeTopic(
      fields[0] as String,
      fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SubscribeTopic obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.topic)
      ..writeByte(1)
      ..write(obj.qos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscribeTopicAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
