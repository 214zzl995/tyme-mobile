import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tyme/utils/platform_check.dart';

// 应该在 MyApp 获取完当前的darkMode 之后再设置
// appbar动态设置  return new AnnotatedRegion<SystemUiOverlayStyle>(
//     value: mySystemTheme,
//     child: new MyRoute(),
//  );

Future<void> updateSystemOverlayStyle(BuildContext context) async {
  final brightness = Theme.of(context).brightness;
  await updateSystemOverlayStyleWithBrightness(brightness);
}

Future<void> updateSystemOverlayStyleWithBrightness(
    Brightness brightness) async {
  if (checkPlatform([TargetPlatform.android])) {
    final darkMode = brightness == Brightness.dark;

    final androidSdkInt = await DeviceInfoPlugin()
        .androidInfo
        .then((value) => value.version.sdkInt);
    debugPrint(androidSdkInt.toString());
    final bool edgeToEdge = androidSdkInt >= 29;

    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge); // ignore: unawaited_futures

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          brightness == Brightness.light ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: edgeToEdge
          ? Colors.transparent
          : (darkMode ? Colors.black : Colors.white),
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness:
          darkMode ? Brightness.light : Brightness.dark,
    ));
  } else {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: brightness, // iOS
      statusBarColor: Colors.transparent, // Not relevant to this issue
    ));
  }
}
