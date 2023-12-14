import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:nanoid/nanoid.dart';
import 'package:tyme/data/clint_param.dart';
import 'package:tyme/utils/crypto_utils.dart';

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

  @HiveField(8)
  bool haveRead = false;

  @override
  String toString() {
    return 'ChatMessage{id: $id, topic: $topic, retain: $retain, qos: $qos, mine: $mine, timestamp: $timestamp, content: $content, sender: $sender, receiver: $receiver}';
  }

  insert() async {
    final key = CryptoUtils.md5Encrypt("tyme_chat_${topic.header}");
    await Hive.box<ChatMessage>(key).add(this);
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
  ChatMessage toChatMessage() {
    final payload = this.payload as MqttPublishMessage;
    final message = ChatMessage();
    message.id = nanoid();
    message.topic.topic = topic!;
    message.topic.header = ClintParam.instance.getTopicHeader(topic!);

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

    message.content.raw = const Utf8Decoder().convert(payload.payload.message!);

    if (type == "application/json") {
      message.content.type = MessageType.json;
    } else if (type == "text/markdown") {
      message.content.type = MessageType.markDown;
    }

    message.mine = sender == ClintParam.instance.clintId;
    return message;
  }
}
