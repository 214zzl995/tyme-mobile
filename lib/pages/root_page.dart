import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/clint.dart';
import '../utils/log_cat_utils.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Clint(),
      lazy: false,
      child: child,
    );
  }
}
