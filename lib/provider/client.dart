import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:tyme/data/chat_message.dart';
import 'package:tyme/data/client_param.dart';
import 'package:tyme/data/client_security_param.dart';
import '../notification.dart';

class Client with ChangeNotifier {
  final mqttClient = MqttServerClient("", "");

  MqttConnectionState _clientStatus = MqttConnectionState.disconnected;

  final ClientParam _clientParam;

  bool disposeState = false;

  String? _errorHint;

  /// 控制当前路由 当前路由的消息不显示消息
  SubscribeTopic? _currentTopic;

  /// 缓存未读消息数量 用于显示未读消息数
  Map<SubscribeTopic, int> _topicUnread = {};

  @override
  void dispose() {
    disposeState = true;
    mqttClient.disconnect();
    super.dispose();
  }

  Client(this._clientParam) {
    init();

    mqttClient.onConnected = onConnected;
    mqttClient.onDisconnected = onDisconnected;
    mqttClient.onAutoReconnect = onAutoReconnect;
    mqttClient.onAutoReconnected = onAutoReconnected;

    mqttClient.autoReconnect = true;
    mqttClient.onSubscribed = (topic) {
      debugPrint('tyme::client::::Subscription confirmed for topic $topic');
    };

    mqttClient.pongCallback = pong;

    connect(_clientParam.subscribeTopicWithSystem);
  }

  void restart([ClientParam? clientParam]) {
    mqttClient.disconnect();
    if (clientParam != null) {
      _clientParam
        ..broker = clientParam.broker
        ..port = clientParam.port
        ..clientId = clientParam.clientId
        ..username = clientParam.username
        ..password = clientParam.password
        ..securityParam = clientParam.securityParam;
      init();
    }

    connect(_clientParam.subscribeTopicWithSystem);
  }

  void init() {
    mqttClient.port = _clientParam.port;
    mqttClient.server = _clientParam.broker;
    if (_clientParam.securityParam != null) {
      mqttClient.securityContext = setCertificate(_clientParam.securityParam!);
    }

    final connMess = MqttConnectMessage()
        .withClientIdentifier(_clientParam.clientId)
        .startClean();

    if (_clientParam.username != null && _clientParam.password != null) {
      connMess.authenticateAs(_clientParam.username!, _clientParam.password!);
    }

    mqttClient.connectionMessage = connMess;
    mqttClient.secure = _clientParam.securityParam != null;
  }

  void connect(List<SubscribeTopic> subscribeTopic) async {
    try {
      _updateClientStatus(MqttConnectionState.connecting);
      _startForegroundServiceClient();
      await mqttClient.connect();

      debugPrint(connectionStatus!.state.toString());

      final mqttSubscriptionOption = MqttSubscriptionOption();

      mqttSubscriptionOption.maximumQos = MqttQos.atLeastOnce;

      final mqttSubscriptionList = subscribeTopic.map((topic) {
        final mqttSubscriptionOption = MqttSubscriptionOption();

        mqttSubscriptionOption.maximumQos = MqttQos.values[topic.qos];

        return MqttSubscription(
            MqttSubscriptionTopic(topic.topic), mqttSubscriptionOption);
      }).toList();

      mqttClient.subscribeWithSubscriptionList(mqttSubscriptionList);

      mqttClient.updates
          .listen((List<MqttReceivedMessage<MqttMessage>> c) async {
        for (var message in c) {
          final chatMessage = message.toChatMessage(_clientParam);
          await chatMessage.insert();
          if (chatMessage.sender != _clientParam.clientId &&
              _currentTopic?.topic != chatMessage.topic.header.topic &&
              _currentTopic?.qos != chatMessage.topic.header.qos) {
            chatMessage.showNotification();
          }

          if (_topicUnread.containsKey(chatMessage.topic)) {
            _topicUnread[chatMessage.topic.header] =
                _topicUnread[chatMessage.topic]! + 1;
          } else {
            _topicUnread[chatMessage.topic.header] = 1;
          }
        }
      });
    } on Exception catch (e) {
      debugPrint('tyme::client exception - $e');
      _errorHint = e.toString();
      mqttClient.disconnect();
    }
  }

  /// 获取特定topic的Stream
  Stream<List<(int, ChatMessage)>> messagesByTopicStream(SubscribeTopic topic) {
    MqttTopicFilter topicFilter =
        MqttTopicFilter(topic.topic, mqttClient.updates);

    return topicFilter.updates.map((newMessages) => newMessages
        .map((message) => (-1, message.toChatMessage(_clientParam)))
        .toList());
  }

  void onDisconnected() {
    String reasonString = mqttClient.connectionStatus!.reasonString ?? "";
    _updateForegroundServiceDescription(
        "🤨 Client Disconnected \n $reasonString");
    _updateClientStatus();
  }

  /// The successful connect callback
  void onConnected() {
    _updateClientStatus();
    _updateForegroundServiceDescription("😀 Client Connected!");
    _errorHint = null;
  }

  void onAutoReconnect() {
    _updateForegroundServiceDescription("🙄 Client AutoReconnect!");
    _updateClientStatus(MqttConnectionState.connecting);
  }

  void onAutoReconnected() {}

  /// Pong callback
  void pong() {
    debugPrint('tyme::client::Ping response client callback invoked');
  }

  void subscriptionTopic(SubscribeTopic subscribeTopic) {
    bool isExist = clientParam.subscribeTopics
        .where((topic) => topic.topic == subscribeTopic.topic)
        .isNotEmpty;

    if (isExist) {
      return;
    }
    if (mqttClient.connectionStatus != null) {
      if (mqttClient.connectionStatus!.state ==
          MqttConnectionState.connecting) {
        mqttClient.subscribe(
            subscribeTopic.topic, MqttQos.values[subscribeTopic.qos]);
      }
    }

    _clientParam.subscribeTopics = [
      ..._clientParam.subscribeTopics,
      subscribeTopic
    ];

    Hive.box('tyme_config').put("client_param", clientParam);
    Hive.openBox<ChatMessage>(subscribeTopic.hiveKey);
    notifyListeners();
  }

  Future<void> unSubscriptionTopic(SubscribeTopic subscribeTopic) async {
    if (mqttClient.connectionStatus != null) {
      if (mqttClient.connectionStatus!.state ==
          MqttConnectionState.connecting) {
        final mqttSubscriptionOption = MqttSubscriptionOption();
        mqttSubscriptionOption.maximumQos = MqttQos.values[subscribeTopic.qos];
        mqttClient.unsubscribeSubscription(MqttSubscription(
            MqttSubscriptionTopic(subscribeTopic.topic),
            mqttSubscriptionOption));
      }
    }

    _clientParam.subscribeTopics = _clientParam.subscribeTopics
        .where((topic) => topic.topic != subscribeTopic.topic)
        .toList();

    debugPrint(_clientParam.subscribeTopics.hashCode.toString());

    await Hive.box('tyme_config').put("client_param", clientParam);

    final key = subscribeTopic.hiveKey;
    await Hive.box<ChatMessage>(key).deleteFromDisk();

    notifyListeners();
  }

  Future<void> _startForegroundServiceClient() async {
    await _createNotificationChannel();
    await _startForegroundService();
  }

  void _updateClientStatus([MqttConnectionState? state]) {
    _clientStatus = state ?? connectionStatus!.state;
    if (!disposeState) {
      notifyListeners();
    }
  }

  set currentTopic(SubscribeTopic? topic) {
    _currentTopic = topic;
  }

  MqttConnectionState get clientStatus => _clientStatus;

  MqttConnectionStatus? get connectionStatus => mqttClient.connectionStatus;

  ClientParam get clientParam => _clientParam;

  String? get errorHint => _errorHint ?? connectionStatus?.reasonString;
}

setCertificate(ClientSecurityParam clientSecurityParam) {
  Uint8List bytes =
      Uint8List.fromList(utf8.encode(clientSecurityParam.fileContent));
  SecurityContext context = SecurityContext.defaultContext;
  context.setTrustedCertificatesBytes(bytes);
  return context;
}

const foregroundServiceChannelId = "com.leri.tyme";
const foregroundServiceChannelName = "client_foreground_service";

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
