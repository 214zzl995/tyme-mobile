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
  String publish = "";

  @HiveField(8)
  String receiver = "";
}

@HiveType(typeId: 4)
class Topic {
  @HiveField(0)
  String topic = "";

  @HiveField(1)
  String? header;
}

@HiveType(typeId: 5)
class MessageContent {
  @HiveField(0)
  MessageType type = MessageType.markDown;

  @HiveField(1)
  String raw = "";
}

@HiveType(typeId: 6)
enum MessageType {
  @HiveField(0)
  markDown,
  @HiveField(1)
  json
}

extension ChatMqttMessage on MqttReceivedMessage<MqttPublishMessage> {
  Object toChatMessage() {
    final message = ChatMessage();
    message.id = nanoid();
    message.topic.topic = topic!;
    message.retain = payload.header!.retain;
    message.qos = payload.header!.qos.index;
    message.timestamp = DateTime.now().millisecondsSinceEpoch;

    final userProperty = payload.variableHeader!.userProperty;

    message.publish = userProperty
            .firstWhere((element) => element.pairName == "publish")
            .pairValue ??
        "";

    message.receiver = userProperty
            .firstWhere((element) => element.pairName == "receiver")
            .pairValue ??
        "";

    message.mine = false;
    return message;
  }
}
