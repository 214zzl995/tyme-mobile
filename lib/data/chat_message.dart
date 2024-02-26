import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:nanoid/nanoid.dart';
import 'package:tyme/data/client_param.dart';

import '../notification.dart';

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
  bool mine = false;

  @HiveField(4)
  int timestamp = 0;

  @HiveField(5)
  MessageContent content = MessageContent();

  @HiveField(6)
  String sender = "";

  @HiveField(7)
  String receiver = "";

  @override
  String toString() {
    return 'ChatMessage{id: $id, topic: $topic, retain: $retain,  mine: $mine, timestamp: $timestamp, content: $content, sender: $sender, receiver: $receiver}';
  }

  insert() async {
    final key = topic.header.hiveKey;
    await Hive.box<ChatMessage>(key).add(this);
  }

  void showNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('your channel id', 'your channel name',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: '🔔 New Messages');
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.show(notificationId++,
        "$sender:${topic.header.topic}", content.raw, notificationDetails,
        payload: 'item x');
  }
}

@HiveType(typeId: 4)
class Topic {
  @HiveField(0)
  String topic = "";

  @HiveField(1)
  SubscribeTopic header = SubscribeTopic.empty();

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
  ChatMessage toChatMessage(ClientParam clientParam) {
    final payload = this.payload as MqttPublishMessage;
    final message = ChatMessage();
    message.id = nanoid();
    message.topic.topic = topic!;
    message.topic.header =
        clientParam.getTopicHeader(topic!, payload.header!.qos.index);

    message.retain = payload.header!.retain;
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
            .firstWhereOrNull((element) => element.pairName == "receiver")
            ?.pairValue ??
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

    message.mine = sender == clientParam.clientId;
    return message;
  }
}
