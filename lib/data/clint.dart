import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tyme/data/clint_param.dart';
import 'package:tyme/data/clint_security_param.dart';

import '../main.dart';

class Clint extends ChangeNotifier {
  final bool topicNotified = false;

  final mqttClint = MqttServerClient("", "");

  MqttConnectionState _clintStatus = MqttConnectionState.disconnected;

  @override
  void dispose() {
    mqttClint.disconnect();
    super.dispose();
  }

  Clint(ClintParam clintParam) {
    mqttClint.port = clintParam.port;
    mqttClint.server = clintParam.broker;
    if (clintParam.securityParam != null) {
      mqttClint.securityContext = setCertificate(clintParam.securityParam!);
    }

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clintParam.clintId)
        .startClean();

    if (clintParam.username != null && clintParam.password != null) {
      connMess.authenticateAs(clintParam.username!, clintParam.password!);
    }

    mqttClint.connectionMessage = connMess;
    mqttClint.keepAlivePeriod = 60;
    mqttClint.secure = clintParam.securityParam != null;

    mqttClint.onConnected = onConnected;
    mqttClint.onDisconnected = onDisconnected;

    mqttClint.onSubscribed = (topic) {
      debugPrint('EXAMPLE::Subscription confirmed for topic $topic');
    };

    connect();
  }

  void connect() async {
    try {
      _clintStatus = MqttConnectionState.connecting;
      notifyListeners();
      await mqttClint.connect();
      mqttClint.subscribe("system/#", MqttQos.atLeastOnce);
      mqttClint.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final pt =
            MqttUtilities.bytesToStringAsString(recMess.payload.message!);
        _showNotification();
      });
    } on Exception catch (e) {
      debugPrint('tyme::client exception - $e');
      mqttClint.disconnect();
    }
  }

  /// 获取特定topic的Stream
  Stream<List<MqttReceivedMessage<MqttMessage>>> msgByTopic(String topic) {
    MqttTopicFilter topicFilter = MqttTopicFilter(topic, mqttClint.updates);
    return topicFilter.updates
        .startWithMany([]).scan<List<MqttReceivedMessage<MqttMessage>>>(
      (accumulatedMessages, newMessages, _) {
        return [...accumulatedMessages, ...newMessages];
      },
      [],
    );
  }

  void disconnect() {
    mqttClint.disconnect();
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
    notifyListeners();
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
