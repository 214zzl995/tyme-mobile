import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:rxdart/rxdart.dart';

import '../main.dart';

class Clint extends ChangeNotifier {
  final bool topicNotified = false;

  final mqttClint = MqttServerClient.withPort(
      'k37bbe35.ala.cn-hangzhou.emqxsl.cn', 'flutter_client', 8883);

  MqttConnectionState _clintStatus = MqttConnectionState.disconnected;

  @override
  void dispose() {
    mqttClint.disconnect();
    super.dispose();
  }

  Clint() {
    mqttClint.securityContext = setCertificate();

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .authenticateAs("leri", "R7ddsQxAGchQPQB");

    mqttClint.connectionMessage = connMess;
    mqttClint.keepAlivePeriod = 60;
    mqttClint.secure = true;

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
        final pt = MqttUtilities.bytesToStringAsString(recMess.payload.message!);
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
    debugPrint(
        'tyme::client::OnDisconnected 客户端回调 - 客户端断开连接');
    if (mqttClint.connectionStatus!.disconnectionOrigin == MqttDisconnectionOrigin.solicited) {
      if (topicNotified) {
        debugPrint(
            'tyme::client::OnDisconnected 回调是主动的，主题已被通知');
      } else {
        debugPrint(
            'tyme::client::OnDisconnected 回调是主动的，主题尚未被通知');
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

setCertificate() {
  const certificateString = """
  ------WebKitFormBoundaryfj0TUT6BVw7ROQ48
Content-Disposition: form-data; name="file"; filename="emqxsl-ca.crt"
Content-Type: application/x-x509-ca-cert

-----BEGIN CERTIFICATE-----
MIIDrzCCApegAwIBAgIQCDvgVpBCRrGhdWrJWZHHSjANBgkqhkiG9w0BAQUFADBh
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
QTAeFw0wNjExMTAwMDAwMDBaFw0zMTExMTAwMDAwMDBaMGExCzAJBgNVBAYTAlVT
MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IENBMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4jvhEXLeqKTTo1eqUKKPC3eQyaKl7hLOllsB
CSDMAZOnTjC3U/dDxGkAV53ijSLdhwZAAIEJzs4bg7/fzTtxRuLWZscFs3YnFo97
nh6Vfe63SKMI2tavegw5BmV/Sl0fvBf4q77uKNd0f3p4mVmFaG5cIzJLv07A6Fpt
43C/dxC//AH2hdmoRBBYMql1GNXRor5H4idq9Joz+EkIYIvUX7Q6hL+hqkpMfT7P
T19sdl6gSzeRntwi5m3OFBqOasv+zbMUZBfHWymeMr/y7vrTC0LUq7dBMtoM1O/4
gdW7jVg/tRvoSSiicNoxBN33shbyTApOB6jtSj1etX+jkMOvJwIDAQABo2MwYTAO
BgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUA95QNVbR
TLtm8KPiGxvDl7I90VUwHwYDVR0jBBgwFoAUA95QNVbRTLtm8KPiGxvDl7I90VUw
DQYJKoZIhvcNAQEFBQADggEBAMucN6pIExIK+t1EnE9SsPTfrgT1eXkIoyQY/Esr
hMAtudXH/vTBH1jLuG2cenTnmCmrEbXjcKChzUyImZOMkXDiqw8cvpOp/2PV5Adg
06O/nVsJ8dWO41P0jmP6P6fbtGbfYmbW0W5BjfIttep3Sp+dWOIrWcBAI+0tKIJF
PnlUkiaY4IBIqDfv8NZ5YBberOgOzW6sRBc4L0na4UU+Krk2U886UAb3LujEV0ls
YSEY1QSteDwsOoBrp+uvFRTp2InBuThs4pFsiv9kuXclVzDAGySj4dzp30d8tbQk
CAUw7C29C79Fv1C5qfPrmAESrciIxpg0X40KPMbp1ZWVbd4=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIEqjCCA5KgAwIBAgIQAnmsRYvBskWr+YBTzSybsTANBgkqhkiG9w0BAQsFADBh
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
QTAeFw0xNzExMjcxMjQ2MTBaFw0yNzExMjcxMjQ2MTBaMG4xCzAJBgNVBAYTAlVT
MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
b20xLTArBgNVBAMTJEVuY3J5cHRpb24gRXZlcnl3aGVyZSBEViBUTFMgQ0EgLSBH
MTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALPeP6wkab41dyQh6mKc
oHqt3jRIxW5MDvf9QyiOR7VfFwK656es0UFiIb74N9pRntzF1UgYzDGu3ppZVMdo
lbxhm6dWS9OK/lFehKNT0OYI9aqk6F+U7cA6jxSC+iDBPXwdF4rs3KRyp3aQn6pj
pp1yr7IB6Y4zv72Ee/PlZ/6rK6InC6WpK0nPVOYR7n9iDuPe1E4IxUMBH/T33+3h
yuH3dvfgiWUOUkjdpMbyxX+XNle5uEIiyBsi4IvbcTCh8ruifCIi5mDXkZrnMT8n
wfYCV6v6kDdXkbgGRLKsR4pucbJtbKqIkUGxuZI2t7pfewKRc5nWecvDBZf3+p1M
pA8CAwEAAaOCAU8wggFLMB0GA1UdDgQWBBRVdE+yck/1YLpQ0dfmUVyaAYca1zAf
BgNVHSMEGDAWgBQD3lA1VtFMu2bwo+IbG8OXsj3RVTAOBgNVHQ8BAf8EBAMCAYYw
HQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMBIGA1UdEwEB/wQIMAYBAf8C
AQAwNAYIKwYBBQUHAQEEKDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
Y2VydC5jb20wQgYDVR0fBDswOTA3oDWgM4YxaHR0cDovL2NybDMuZGlnaWNlcnQu
Y29tL0RpZ2lDZXJ0R2xvYmFsUm9vdENBLmNybDBMBgNVHSAERTBDMDcGCWCGSAGG
/WwBAjAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
MAgGBmeBDAECATANBgkqhkiG9w0BAQsFAAOCAQEAK3Gp6/aGq7aBZsxf/oQ+TD/B
SwW3AU4ETK+GQf2kFzYZkby5SFrHdPomunx2HBzViUchGoofGgg7gHW0W3MlQAXW
M0r5LUvStcr82QDWYNPaUy4taCQmyaJ+VB+6wxHstSigOlSNF2a6vg4rgexixeiV
4YSB03Yqp2t3TeZHM9ESfkus74nQyW7pRGezj+TC44xCagCQQOzzNmzEAP2SnCrJ
sNE2DpRVMnL8J6xBRdjmOsC3N6cQuKuRXbzByVBjCqAA8t1L0I+9wXJerLPyErjy
rMKWaBFLmfK/AHNF4ZihwPGOc7w6UHczBZXH5RFzJNnww+WnKuTPI0HfnVH8lg==
-----END CERTIFICATE-----


------WebKitFormBoundaryfj0TUT6BVw7ROQ48--
""";
  Uint8List bytes = Uint8List.fromList(utf8.encode(certificateString));
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
