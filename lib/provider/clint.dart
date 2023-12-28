import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:tyme/data/chat_message.dart';
import 'package:tyme/data/clint_param.dart';
import 'package:tyme/data/clint_security_param.dart';
import '../notification.dart';

class Clint extends ChangeNotifier {
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
    mqttClint.onAutoReconnect = onAutoReconnect;
    mqttClint.onAutoReconnected = onAutoReconnected;
    mqttClint.autoReconnect = true;
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
    mqttClint.secure = _clintParam.securityParam != null;
  }

  void connect(List<SubscribeTopic> subscribeTopic) async {
    try {
      _clintStatus = MqttConnectionState.connecting;
      notifyListeners();
      _startForegroundServiceClint();
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

      mqttClint.updates
          .listen((List<MqttReceivedMessage<MqttMessage>> c) async {
        for (var message in c) {
          final chatMessage = message.toChatMessage(_clintParam);
          await chatMessage.insert();
          if (chatMessage.sender != _clintParam.clintId){
            chatMessage.showNotification();
          }

        }
      });
    } on Exception catch (e) {
      debugPrint('tyme::client exception - $e');
      mqttClint.disconnect();
    }
  }

  /// 获取特定topic的Stream
  Stream<List<(int, ChatMessage)>> messagesByTopicStream(SubscribeTopic topic) {
    MqttTopicFilter topicFilter =
        MqttTopicFilter(topic.topic, mqttClint.updates);

    return topicFilter.updates.map((newMessages) => newMessages
        .map((message) => (-1, message.toChatMessage(_clintParam)))
        .toList());
  }

  void onDisconnected() {
    String reasonString = mqttClint.connectionStatus!.reasonString ?? "";
    _updateForegroundServiceDescription(
        "🤨 Clint Disconnected \n $reasonString");

    _clintStatus = connectionStatus!.state;
    if (!disposeState) {
      notifyListeners();
    }
  }

  /// The successful connect callback
  void onConnected() {
    _clintStatus = connectionStatus!.state;
    notifyListeners();
    _updateForegroundServiceDescription("😀 Clint Connected!");
  }

  void onAutoReconnect() {
    _updateForegroundServiceDescription("🙄 Clint AutoReconnect!");
  }

  void onAutoReconnected() {}

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
    clintParam.addSubscribeTopic(subscribeTopic);

    Hive.box('tyme_config').put("clint_param", clintParam);
    Hive.openBox(subscribeTopic.hiveKey);
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

    final key = subscribeTopic.hiveKey;
    Hive.box(key).deleteFromDisk();
    Hive.box(key).close();

    notifyListeners();
  }

  Future<void> _startForegroundServiceClint() async {
    await _createNotificationChannel();
    await _startForegroundService();
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

const foregroundServiceChannelId = "com.leri.tyme";
const foregroundServiceChannelName = "clint_foreground_service";

Future<void> _createNotificationChannel() async {
  const AndroidNotificationChannel androidNotificationChannel =
      AndroidNotificationChannel(
    foregroundServiceChannelId,
    foregroundServiceChannelName,
    description: '',
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidNotificationChannel);
}

Future<void> _startForegroundService() async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
          foregroundServiceChannelId, foregroundServiceChannelName,
          channelDescription: '',
          importance: Importance.max,
          priority: Priority.high,
          ticker: '');

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.startForegroundService(1, 'Tyme is Running ✨', '😄 Start',
          notificationDetails: androidNotificationDetails, payload: '');
}

// ignore: unused_element
Future<void> _updateForegroundServiceDescription(String description) async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
          foregroundServiceChannelId, foregroundServiceChannelName,
          channelDescription: '',
          importance: Importance.max,
          priority: Priority.high,
          channelAction: AndroidNotificationChannelAction.update);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.startForegroundService(1, 'Tyme is Running ✨', description,
          notificationDetails: androidNotificationDetails, payload: '');
}

// ignore: unused_element
Future<void> _stopForegroundService() async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.stopForegroundService();
}
