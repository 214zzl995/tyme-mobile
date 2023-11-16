import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tyme/pages/demo_page.dart';
import 'package:tyme/pages/root_page.dart';

typedef PathWidgetBuilder = Widget Function(BuildContext, GoRouterState);

class Path {
  const Path(this.name, this.path, this.builder,
      {this.openInSecondScreen = false});

  final String name;

  final String path;

  final PathWidgetBuilder builder;

  final bool openInSecondScreen;
}

class TymeRouteConfiguration {
  static const initial = '/home';

  static List<Path> paths = [
    Path(
      'Home',
      '/home',
      (context, state) => const DemoPage(),
      openInSecondScreen: false,
    ),
    Path(
      'Chat',
      '/chat',
      (context, state) => const DemoPage(),
      openInSecondScreen: false,
    ),
  ];

  static final routers = GoRouter(initialLocation: initial, routes: [
    ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return RootPage(child: child);
        },
        routes: [
          ...List.of(paths).map((path) => GoRoute(
              name: path.name,
              pageBuilder: (context, state) {
                return FadeTransitionPage(
                    key: state.pageKey, child: path.builder(context, state));
              },
              path: path.path)),
        ]),
  ]);
}

class FadeTransitionPage extends CustomTransitionPage<void> {
  /// Creates a [SlideUpFadeTransitionPage].
  FadeTransitionPage({
    required LocalKey super.key,
    required super.child,
  }) : super(
            transitionsBuilder: (BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                    Widget child) =>
                // FadeTransition(opacity: animation, child: child));
                FadeTransition(
                    opacity:
                        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
                      parent: animation,
                      curve: _curve,
                    )),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 1, end: 0)
                          .animate(CurvedAnimation(
                        parent: secondaryAnimation,
                        curve: _curve,
                      )),
                      child: child,
                    )));

  static const Curve _curve = Cubic(1, .19, 0, .81);
}
