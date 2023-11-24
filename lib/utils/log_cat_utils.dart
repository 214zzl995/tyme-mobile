import 'package:flutter/services.dart';

class LogCatUtils {
  static const String _tag = "LogUtils";
  static const _perform = MethodChannel("leri.dev/tyme.log");

  static void d(String message) {
    _perform.invokeMethod("logD", {'tag': _tag, 'msg': message});
  }

  static void e(String message) {
    _perform.invokeMethod("logE", {'tag': _tag, 'msg': message});
  }
}
