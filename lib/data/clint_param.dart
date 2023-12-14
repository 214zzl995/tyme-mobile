import 'package:hive/hive.dart';
import 'package:tyme/utils/crypto_utils.dart';

import 'clint_security_param.dart';

part 'clint_param.g.dart';

@HiveType(typeId: 1)
class ClintParam {
  @HiveField(0)
  String broker = "";

  @HiveField(1)
  int port = -1;

  @HiveField(2)
  String clintId = "";

  @HiveField(3)
  String? username;

  @HiveField(4)
  String? password;

  @HiveField(5)
  ClintSecurityParam? securityParam;

  @HiveField(6)
  List<String> subscribeTopic = [];

  bool get isComplete =>
      broker != "" &&
      port != -1 &&
      clintId != "" &&
      ((username != null) == (password != null));

  copyWith(
      {String? broker,
      int? port,
      String? clintId,
      String? username,
      String? password,
      ClintSecurityParam? securityParam,
      List<String>? subscribeTopic}) {
    final clintParam = ClintParam(
        broker ?? this.broker,
        port ?? this.port,
        clintId ?? this.clintId,
        username ?? this.username,
        password ?? this.password,
        securityParam ?? this.securityParam,
        subscribeTopic ?? this.subscribeTopic);

    return clintParam;
  }

  void from(ClintParam from) {
    broker = from.broker;
    port = from.port;
    clintId = from.clintId;
    username = from.username;
    password = from.password;
    securityParam = from.securityParam;
    subscribeTopic = List.from(from.subscribeTopic);
  }

  ClintParam._();

  ClintParam(
      [this.broker = "",
      this.port = -1,
      this.clintId = "",
      this.username,
      this.password,
      this.securityParam,
      this.subscribeTopic = const []]);

  static final ClintParam instance = ClintParam._();

  List<String> get subscribeTopicWithSystem => [...subscribeTopic, "system/#"];

  List<String> get subscribeTopicWithSystemDbKey => subscribeTopicWithSystem
      .map((topic) => CryptoUtils.md5Encrypt("tyme_chat_$topic"))
      .toList();

  String getTopicHeader(String topic) {
    for (var subscribeTopic in subscribeTopicWithSystem) {
      // 如果 subscribeTopic 以 '#' 结尾，我们只需要检查 topic 是否以 subscribeTopic 的前缀开始
      if (subscribeTopic.endsWith('#')) {
        var prefix = subscribeTopic.substring(0, subscribeTopic.length - 1);
        if (topic.startsWith(prefix)) {
          return subscribeTopic;
        }
      }
      // 如果 subscribeTopic 包含 '+', 我们需要将其分解为各个部分，并与 topic 的相应部分进行比较
      else if (subscribeTopic.contains('+')) {
        var subscribeParts = subscribeTopic.split('/');
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
      else if (subscribeTopic == topic) {
        return subscribeTopic;
      }
    }

    // 如果没有找到匹配的项，返回一个空字符串
    return '';
  }
}
