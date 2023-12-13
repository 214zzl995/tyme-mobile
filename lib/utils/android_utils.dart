import 'dart:io';

import 'package:flutter/services.dart';

class AndroidUtils {
  static const _perform = MethodChannel("leri.dev/tyme.system");

  static void navigateToSystemHome() {
    if (Platform.isAndroid) {
      _perform.invokeMethod('navigateToSystemHome');
    }
  }
}
