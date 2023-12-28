import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:tyme/data/chat_message.dart';
import 'package:tyme/data/clint_param.dart';
import 'package:tyme/data/clint_security_param.dart';
import 'package:tyme/routers.dart';
import 'package:tyme/theme.dart';

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

  if (Platform.isAndroid) {
    await FlutterDisplayMode.setHighRefreshRate();

    await updateSystemOverlayStyleWithBrightness(Brightness.light);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('tyme_config').listenable(keys: []),
      builder: (context, box, widget) {
        return MaterialApp.router(
          supportedLocales: const [Locale("zh", "CN"), Locale("en", "US")],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: TymeRouteConfiguration.routers(box.get("clint_param")),
        );
      },
    );
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


