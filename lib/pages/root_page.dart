import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../clint.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => Clint(),
      lazy: false,
      child: child,
    );
  }
}
