// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 3;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage()
      ..id = fields[0] as String
      ..topic = fields[1] as Topic
      ..retain = fields[2] as bool
      ..qos = fields[3] as int
      ..mine = fields[4] as bool
      ..timestamp = fields[5] as int
      ..content = fields[6] as MessageContent
      ..publish = fields[7] as String
      ..receiver = fields[8] as String;
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.topic)
      ..writeByte(2)
      ..write(obj.retain)
      ..writeByte(3)
      ..write(obj.qos)
      ..writeByte(4)
      ..write(obj.mine)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.content)
      ..writeByte(7)
      ..write(obj.publish)
      ..writeByte(8)
      ..write(obj.receiver);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TopicAdapter extends TypeAdapter<Topic> {
  @override
  final int typeId = 4;

  @override
  Topic read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Topic()
      ..topic = fields[0] as String
      ..header = fields[1] as String?;
  }

  @override
  void write(BinaryWriter writer, Topic obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.topic)
      ..writeByte(1)
      ..write(obj.header);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageContentAdapter extends TypeAdapter<MessageContent> {
  @override
  final int typeId = 5;

  @override
  MessageContent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageContent()
      ..type = fields[0] as MessageType
      ..raw = fields[1] as String;
  }

  @override
  void write(BinaryWriter writer, MessageContent obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.raw);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageContentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageTypeAdapter extends TypeAdapter<MessageType> {
  @override
  final int typeId = 6;

  @override
  MessageType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageType.markDown;
      case 1:
        return MessageType.json;
      default:
        return MessageType.markDown;
    }
  }

  @override
  void write(BinaryWriter writer, MessageType obj) {
    switch (obj) {
      case MessageType.markDown:
        writer.writeByte(0);
        break;
      case MessageType.json:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
