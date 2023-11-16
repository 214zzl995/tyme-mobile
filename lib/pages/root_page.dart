import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routers.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
