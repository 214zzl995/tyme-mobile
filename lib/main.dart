import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:tyme/data/chat_message.dart';
import 'package:tyme/data/clint_param.dart';
import 'package:tyme/data/clint_security_param.dart';
import 'package:tyme/routers.dart';

import 'notification.dart';

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initNotifications();

  await _hiveInit();

  AndroidDeviceInfo? deviceInfo;

  if (Platform.isAndroid) {
    await FlutterDisplayMode.setHighRefreshRate();
    deviceInfo = await DeviceInfoPlugin().androidInfo;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  runApp(MyApp(
    androidDeviceInfo: deviceInfo,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.androidDeviceInfo});

  final AndroidDeviceInfo? androidDeviceInfo;

  @override
  Widget build(BuildContext context) {
    return Provider(
        create: (_) => androidDeviceInfo,
        child: ValueListenableBuilder(
          valueListenable: Hive.box('tyme_config').listenable(keys: []),
          builder: (context, box, widget) {
            return MaterialApp.router(
              supportedLocales: const [Locale("zh", "CN"), Locale("en", "US")],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              themeMode: Theme.of(context).brightness == Brightness.dark
                  ? ThemeMode.dark
                  : ThemeMode.light,
              routerConfig:
                  TymeRouteConfiguration.routers(box.get("clint_param")),
            );
          },
        ));
  }
}

Future<void> _hiveInit() async {
  Hive.registerAdapter(ClintParamAdapter());
  Hive.registerAdapter(ClintSecurityParamAdapter());
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(TopicAdapter());
  Hive.registerAdapter(MessageContentAdapter());
  Hive.registerAdapter(MessageTypeAdapter());
  Hive.registerAdapter(SubscribeTopicAdapter());

  await Hive.initFlutter();
  await Hive.openBox("tyme_config");
  await Hive.openBox("tyme_chat_read_index");
  final ClintParam? clintParam = Hive.box("tyme_config").get("clint_param");
  if (clintParam != null) {
    for (var key in clintParam.subscribeTopicWithSystemDbKey) {
      Hive.openBox<ChatMessage>(key);
    }
  }
}
