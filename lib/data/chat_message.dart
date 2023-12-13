import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:nanoid/nanoid.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 3)
class ChatMessage {
  @HiveField(0)
  String id = "";

  @HiveField(1)
  Topic topic = Topic();

  @HiveField(2)
  bool retain = false;

  @HiveField(3)
  int qos = 0;

  @HiveField(4)
  bool mine = false;

  @HiveField(5)
  int timestamp = 0;

  @HiveField(6)
  MessageContent content = MessageContent();

  @HiveField(7)
  String sender = "";

  @HiveField(8)
  String receiver = "";

  @override
  String toString() {
    return 'ChatMessage{id: $id, topic: $topic, retain: $retain, qos: $qos, mine: $mine, timestamp: $timestamp, content: $content, sender: $sender, receiver: $receiver}';
  }
}

@HiveType(typeId: 4)
class Topic {
  @HiveField(0)
  String topic = "";

  @HiveField(1)
  String? header;

  @override
  String toString() {
    return 'Topic{topic: $topic, header: $header}';
  }
}

@HiveType(typeId: 5)
class MessageContent {
  @HiveField(0)
  MessageType type = MessageType.markDown;

  @HiveField(1)
  String raw = "";

  @override
  String toString() {
    return 'MessageContent{type: $type, raw: $raw}';
  }
}

@HiveType(typeId: 6)
enum MessageType {
  @HiveField(0)
  markDown,
  @HiveField(1)
  json
}

extension ChatMqttMessage on MqttReceivedMessage<MqttMessage> {
  ChatMessage toChatMessage(String self) {
    final payload = this.payload as MqttPublishMessage;
    final message = ChatMessage();
    message.id = nanoid();
    message.topic.topic = topic!;
    message.retain = payload.header!.retain;
    message.qos = payload.header!.qos.index;
    message.timestamp = DateTime.now().millisecondsSinceEpoch;

    final variableHeader = payload.variableHeader;

    if (variableHeader == null) {
      throw ArgumentError('payload.variableHeader is null');
    }

    final userProperty = variableHeader.userProperty;

    final sender = userProperty
        .firstWhere((element) => element.pairName == "sender")
        .pairValue;

    if (sender == null) {
      throw ArgumentError('Sender is null');
    }

    message.sender = sender;

    final receiver = userProperty
            .firstWhere((element) => element.pairName == "receiver")
            .pairValue ??
        "";

    message.receiver = receiver;

    final contentType = variableHeader.contentType;

    if (contentType == null) {
      throw ArgumentError('ContentType is null');
    }

    final contentTypeList = contentType.split(";");
    final type = contentTypeList[0];
    final charset = (contentTypeList.length > 1
        ? contentTypeList[1].substring(8)
        : "utf-8");

    final messageContent = MessageContent();
    messageContent.raw = const Utf8Decoder().convert(payload.payload.message!);

    if (type == "application/json") {
      messageContent.type = MessageType.json;
    } else if (type == "text/markdown") {
      messageContent.type = MessageType.markDown;
    }

    message.content = messageContent;

    message.mine = sender == self;
    return message;
  }
}
