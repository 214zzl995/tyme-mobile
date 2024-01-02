import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tyme/data/client_param.dart';
import 'package:tyme/utils/android_utils.dart';
import '../provider/client.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ClientParam? clientParam = Hive.box('tyme_config').get("client_param");
    if (clientParam == null) {
      GoRouter.of(context).goNamed("Guide");
    }
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        AndroidUtils.navigateToSystemHome();
      },
      child: ChangeNotifierProvider(
        create: (_) => Client(clientParam!),
        lazy: false,
        child: child,
      ),
    );
  }
}
