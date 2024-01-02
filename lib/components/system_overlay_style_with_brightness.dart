import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/single_child_widget.dart';

import '../utils/platform_check.dart';

class SystemOverlayStyleWithBrightness extends SingleChildStatefulWidget {
  const SystemOverlayStyleWithBrightness(
      {Key? key,
      required Widget child,
      required this.systemNavigationBarColor,
      this.sized = true})
      : super(key: key, child: child);

  final Color systemNavigationBarColor;
  final bool sized;

  @override
  State<StatefulWidget> createState() => _SystemOverlayStyleWithBrightness();
}

class _SystemOverlayStyleWithBrightness
    extends SingleChildState<SystemOverlayStyleWithBrightness> {
  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return AnnotatedRegion(
      value: getSystemOverlayStyleWithBrightness(context),
      sized: widget.sized,
      child: child!,
    );
  }

  SystemUiOverlayStyle getSystemOverlayStyleWithBrightness(
      BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final darkMode = brightness == Brightness.dark;
    if (checkPlatform([TargetPlatform.android])) {
      return SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            brightness == Brightness.light ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness:
            darkMode ? Brightness.light : Brightness.dark,
      );
    } else {
      return SystemUiOverlayStyle(
        statusBarBrightness: brightness, // iOS
        statusBarColor: Colors.transparent, // Not relevant to this issue
      );
    }
  }
}
