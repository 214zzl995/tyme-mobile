import 'package:hive/hive.dart';
import 'package:tyme/utils/crypto_utils.dart';

import 'client_security_param.dart';

part 'client_param.g.dart';

@HiveType(typeId: 1)
class ClientParam {
  @HiveField(0)
  String broker = "";

  @HiveField(1)
  int port = -1;

  @HiveField(2)
  String clientId = "";

  @HiveField(3)
  String? username;

  @HiveField(4)
  String? password;

  @HiveField(5)
  ClientSecurityParam? securityParam;

  @HiveField(6)
  List<SubscribeTopic> subscribeTopics = List.empty();

  bool get isComplete =>
      broker != "" &&
      port != -1 &&
      clientId != "" &&
      ((username != null) == (password != null));

  copyWith(
      {String? broker,
      int? port,
      String? clientId,
      String? username,
      String? password,
      ClientSecurityParam? securityParam,
      List<SubscribeTopic>? subscribeTopics}) {
    final clientParam = ClientParam(
        broker ?? this.broker,
        port ?? this.port,
        clientId ?? this.clientId,
        username ?? this.username,
        password ?? this.password,
        securityParam ?? this.securityParam,
        subscribeTopics ?? this.subscribeTopics);

    return clientParam;
  }

  void from(ClientParam from) {
    broker = from.broker;
    port = from.port;
    clientId = from.clientId;
    username = from.username;
    password = from.password;
    securityParam = from.securityParam;
    subscribeTopics = List.from(from.subscribeTopics);
  }

  bool equals(ClientParam other) {
    return broker == other.broker &&
        port == other.port &&
        clientId == other.clientId &&
        username == other.username &&
        password == other.password &&
        securityParam?.fileContent == other.securityParam?.fileContent;
  }

  ClientParam(
      [this.broker = "",
      this.port = -1,
      this.clientId = "",
      this.username,
      this.password,
      this.securityParam,
      this.subscribeTopics = const []]);

  List<SubscribeTopic> get subscribeTopicWithSystem =>
      [...subscribeTopics, SubscribeTopic("system/#", 1)];

  List<String> get subscribeTopicWithSystemDbKey => subscribeTopicWithSystem
      .map((topic) => CryptoUtils.md5Encrypt("tyme_chat_${topic.topic}"))
      .toList();

  SubscribeTopic getTopicHeader(String topic, int qos) {
    for (var subscribeTopic in subscribeTopicWithSystem) {
      if (qos != subscribeTopic.qos) {
        continue;
      }
      // 如果 subscribeTopic 以 '#' 结尾，我们只需要检查 topic 是否以 subscribeTopic 的前缀开始
      if (subscribeTopic.topic.endsWith('#')) {
        var prefix =
            subscribeTopic.topic.substring(0, subscribeTopic.topic.length - 1);
        if (topic.startsWith(prefix)) {
          return subscribeTopic;
        }
      }
      // 如果 subscribeTopic 包含 '+', 我们需要将其分解为各个部分，并与 topic 的相应部分进行比较
      else if (subscribeTopic.topic.contains('+')) {
        var subscribeParts = subscribeTopic.topic.split('/');
        var topicParts = topic.split('/');
        if (subscribeParts.length != topicParts.length) {
          continue;
        }
        bool match = true;
        for (int i = 0; i < subscribeParts.length; i++) {
          if (subscribeParts[i] != '+' && subscribeParts[i] != topicParts[i]) {
            match = false;
            break;
          }
        }
        if (match) {
          return subscribeTopic;
        }
      }
      // 如果 subscribeTopic 不包含任何通配符，我们只需要检查它是否等于 topic
      else if (subscribeTopic.topic == topic) {
        return subscribeTopic;
      }
    }

    return SubscribeTopic.empty();
  }

  void addSubscribeTopic(SubscribeTopic topic) {
    List<SubscribeTopic> topics = List.from(subscribeTopics);
    topics.add(topic);
    subscribeTopics = topics;
  }
}

@HiveType(typeId: 7)
class SubscribeTopic {
  @HiveField(0)
  String topic = "";
  @HiveField(1)
  int qos = -1;

  SubscribeTopic(this.topic, this.qos);

  SubscribeTopic.empty();

  String get hiveKey => CryptoUtils.md5Encrypt("tyme_chat_$topic");

  @override
  String toString() {
    return 'SubscribeTopic{topic: $topic, qos: $qos}';
  }
}
