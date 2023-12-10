import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tyme/data/clint_param.dart';

import '../data/clint.dart';
class RootPage extends StatelessWidget {
  const RootPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {

    final ClintParam? clintParam = Hive.box('tyme_config').get("clint_param");
    if (clintParam == null) {
      GoRouter.of(context).goNamed("Guide");
    }
    return ChangeNotifierProvider(
      create: (_) => Clint(clintParam!),
      lazy: false,
      child: child,
    );
  }
}
