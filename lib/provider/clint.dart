import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tyme/data/chat_message.dart';
import 'package:tyme/data/clint_param.dart';
import 'package:tyme/data/clint_security_param.dart';

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

    debugPrint(_clintParam.subscribeTopics.toString());

    mqttClint.onConnected = onConnected;
    mqttClint.onDisconnected = onDisconnected;
    mqttClint.onSubscribed = (topic) {
      debugPrint('tyme::client::::Subscription confirmed for topic $topic');
    };

    connect(_clintParam.subscribeTopicWithSystem);
  }

  void restart([ClintParam? clintParam]) {
    mqttClint.disconnect();
    if (clintParam != null) {
      init();
    }

    connect(_clintParam.subscribeTopicWithSystem);
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

  void connect(List<SubscribeTopic> subscribeTopic) async {
    try {
      _clintStatus = MqttConnectionState.connecting;
      notifyListeners();
      await mqttClint.connect();

      final mqttSubscriptionOption = MqttSubscriptionOption();

      mqttSubscriptionOption.maximumQos = MqttQos.atLeastOnce;

      final mqttSubscriptionList = subscribeTopic.map((topic) {
        final mqttSubscriptionOption = MqttSubscriptionOption();

        mqttSubscriptionOption.maximumQos = MqttQos.values[topic.qos];

        return MqttSubscription(
            MqttSubscriptionTopic(topic.topic), mqttSubscriptionOption);
      }).toList();

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
  Stream<List<(int, ChatMessage)>> msgByTopic(SubscribeTopic topic,
      {List<(int, ChatMessage)> initialData = const []}) {
    MqttTopicFilter topicFilter =
        MqttTopicFilter(topic.topic, mqttClint.updates);

    return topicFilter.updates
        .map((newMessages) => newMessages
            .map((message) => (0, message.toChatMessage(_clintParam)))
            .toList())
        .startWith(initialData)
        .scan<List<(int, ChatMessage)>>(
      (accumulatedMessages, newMessages, _) {
        final accumulatedIsNotEmptyIndex =
            accumulatedMessages.isNotEmpty ? 1 : 0;
        final maxIndex =
            accumulatedMessages.isNotEmpty ? accumulatedMessages.last.$1 : 0;

        final newMessagesWithIndex = newMessages
            .mapIndexed((index, msg) =>
                (index + maxIndex + accumulatedIsNotEmptyIndex, msg.$2))
            .toList();

        return [...accumulatedMessages, ...newMessagesWithIndex];
      },
      [],
    );
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

  void subscriptionTopic(SubscribeTopic subscribeTopic) {
    bool isExist = clintParam.subscribeTopics
        .where((topic) => topic.topic == subscribeTopic.topic)
        .isNotEmpty;

    if (isExist) {
      return;
    }
    if (mqttClint.connectionStatus != null) {
      if (mqttClint.connectionStatus!.state == MqttConnectionState.connecting) {
        mqttClint.subscribe(
            subscribeTopic.topic, MqttQos.values[subscribeTopic.qos]);
      }
    }
    clintParam.subscribeTopics.add(subscribeTopic);

    Hive.box('tyme_config').put("clint_param", clintParam);
    Hive.openBox(subscribeTopic.getHiveKey());
    notifyListeners();
  }

  void unSubscriptionTopic(SubscribeTopic subscribeTopic) {
    if (mqttClint.connectionStatus != null) {
      if (mqttClint.connectionStatus!.state == MqttConnectionState.connecting) {
        final mqttSubscriptionOption = MqttSubscriptionOption();
        mqttSubscriptionOption.maximumQos = MqttQos.values[subscribeTopic.qos];
        mqttClint.unsubscribeSubscription(MqttSubscription(
            MqttSubscriptionTopic(subscribeTopic.topic),
            mqttSubscriptionOption));
      }
    }
    clintParam.subscribeTopics.remove(subscribeTopic);

    Hive.box('tyme_config').put("clint_param", clintParam);

    final key = subscribeTopic.getHiveKey();
    Hive.box(key).deleteFromDisk();
    Hive.box(key).close();

    notifyListeners();
  }

  MqttConnectionState get clintStatus => _clintStatus;

  MqttConnectionStatus? get connectionStatus => mqttClint.connectionStatus;

  ClintParam get clintParam => _clintParam;
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
