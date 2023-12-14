import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tyme/data/chat_message.dart';
import 'package:tyme/data/clint_param.dart';
import 'package:tyme/data/clint_security_param.dart';
import 'package:tyme/utils/crypto_utils.dart';

import '../main.dart';

/// 是否出现修改只需要判断 Clint的 _clintParam 是否等于 Hive.box('tyme_config').listenable(keys: ["clint_param"]) equals 为false时需要重启
class Clint extends ChangeNotifier {
  final bool topicNotified = false;

  final mqttClint = MqttServerClient("", "");

  MqttConnectionState _clintStatus = MqttConnectionState.disconnected;

  final ClintParam _clintParam;

  bool disposeState = false;

  @override
  void dispose() {
    disposeState = true;
    mqttClint.disconnect();
    super.dispose();
  }

  Clint(this._clintParam) {
    init();

    debugPrint(_clintParam.subscribeTopic.toString());

    mqttClint.onConnected = onConnected;
    mqttClint.onDisconnected = onDisconnected;
    mqttClint.onSubscribed = (topic) {
      debugPrint('tyme::client::::Subscription confirmed for topic $topic');
    };

    connect(_clintParam.subscribeTopic);
  }

  void restart([ClintParam? clintParam]) {
    mqttClint.disconnect();
    if (clintParam != null) {
      init();
    }

    connect(_clintParam.subscribeTopic);
  }

  void init() {
    mqttClint.port = _clintParam.port;
    mqttClint.server = _clintParam.broker;
    if (_clintParam.securityParam != null) {
      mqttClint.securityContext = setCertificate(_clintParam.securityParam!);
    }

    final connMess = MqttConnectMessage()
        .withClientIdentifier(_clintParam.clintId)
        .startClean();

    if (_clintParam.username != null && _clintParam.password != null) {
      connMess.authenticateAs(_clintParam.username!, _clintParam.password!);
    }

    mqttClint.connectionMessage = connMess;
    mqttClint.keepAlivePeriod = 60;
    mqttClint.secure = _clintParam.securityParam != null;
  }

  void connect(List<String> subscribeTopic) async {
    try {
      _clintStatus = MqttConnectionState.connecting;
      notifyListeners();
      await mqttClint.connect();

      final mqttSubscriptionOption = MqttSubscriptionOption();

      mqttSubscriptionOption.maximumQos = MqttQos.atLeastOnce;

      final mqttSubscriptionList = subscribeTopic
          .map((topic) => MqttSubscription(
              MqttSubscriptionTopic(topic), mqttSubscriptionOption))
          .toList();

      mqttClint.subscribe("system/#", MqttQos.atLeastOnce);

      mqttClint.subscribeWithSubscriptionList(mqttSubscriptionList);

      mqttClint.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        for (var message in c) {
          final chatMessage = message.toChatMessage(_clintParam);
          chatMessage.insert();
        }
        _showNotification();
      });
    } on Exception catch (e) {
      debugPrint('tyme::client exception - $e');
      mqttClint.disconnect();
    }
  }

  /// 获取特定topic的Stream
  Stream<List<ChatMessage>> msgByTopic(String topic) {
    MqttTopicFilter topicFilter = MqttTopicFilter(topic, mqttClint.updates);
    final box =
        Hive.box<ChatMessage>(CryptoUtils.md5Encrypt("tyme_chat_$topic"));
    final skipCount = box.length > 100 ? box.length - 100 : 0;
    List<ChatMessage>? startMessages = box.values.skip(skipCount).toList();

    return topicFilter.updates
        .map((newMessages) => newMessages
            .map((message) => message.toChatMessage(_clintParam))
            .toList())
        .startWith(startMessages)
        .scan<List<ChatMessage>>(
      (accumulatedMessages, newMessages, _) {
        return [...accumulatedMessages, ...newMessages];
      },
      [],
    );
  }

  List<ChatMessage> getTopicInitialData(String topic) {
    final box =
        Hive.box<ChatMessage>(CryptoUtils.md5Encrypt("tyme_chat_$topic"));
    final skipCount = box.length > 100 ? box.length - 100 : 0;
    List<ChatMessage>? startMessages = box.values.skip(skipCount).toList();
    return startMessages;
  }

  void onDisconnected() {
    debugPrint('tyme::client::OnDisconnected 客户端回调 - 客户端断开连接');
    if (mqttClint.connectionStatus!.disconnectionOrigin ==
        MqttDisconnectionOrigin.solicited) {
      if (topicNotified) {
        debugPrint('tyme::client::OnDisconnected 回调是主动的，主题已被通知');
      } else {
        debugPrint('tyme::client::OnDisconnected 回调是主动的，主题尚未被通知');
      }
    }
    _clintStatus = connectionStatus!.state;
    if (!disposeState) {
      notifyListeners();
    }
  }

  /// The successful connect callback
  void onConnected() {
    _clintStatus = connectionStatus!.state;
    notifyListeners();
    debugPrint("tyme::client::OnConnected 客户端回调 - 客户端连接成功当前状态: $_clintStatus");
  }

  /// Pong callback
  void pong() {
    debugPrint('tyme::client::Ping response client callback invoked');
  }

  MqttConnectionState get clintStatus => _clintStatus;

  MqttConnectionStatus? get connectionStatus => mqttClint.connectionStatus;

  ClintParam get clintParam  => _clintParam;

}

setCertificate(ClintSecurityParam clintSecurityParam) {
  Uint8List bytes =
      Uint8List.fromList(utf8.encode(clintSecurityParam.fileContent));
  SecurityContext context = SecurityContext.defaultContext;
  context.setTrustedCertificatesBytes(bytes);
  return context;
}

int id = 0;

Future<void> _showNotification() async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails('your channel id', 'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');
  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails);
  await flutterLocalNotificationsPlugin.show(
      id++, 'plain title', 'plain body', notificationDetails,
      payload: 'item x');
}
