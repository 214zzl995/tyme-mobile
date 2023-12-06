import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tyme/data/clint_param.dart';
import 'package:tyme/pages/chat_page.dart';
import 'package:tyme/pages/demo_page.dart';
import 'package:tyme/pages/guide_page.dart';
import 'package:tyme/pages/home_page.dart';
import 'package:tyme/pages/main_page.dart';
import 'package:tyme/pages/root_page.dart';

// https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/others/custom_stateful_shell_route.dart
// stateful_shell_route with animation

typedef PathWidgetBuilder = Widget Function(BuildContext, GoRouterState);

class Path {
  Path(this.name, this.path, this.builder,
      {this.openInSecondScreen = false, this.icon, this.navigatorKey});

  final String name;

  final String path;

  final PathWidgetBuilder builder;

  final bool openInSecondScreen;

  final Widget? icon;

  final GlobalKey<NavigatorState>? navigatorKey;
}

class TymeRouteConfiguration {
  static const initial = '/home';
  static const initInitial = '/guide';

  static List<Path> navPaths = [
    Path(
      'Home',
      '/home',
      (context, state) => const HomePage(),
      openInSecondScreen: false,
      icon: const Icon(Icons.home),
    ),
    Path(
      'Chat',
      '/chat',
      (context, state) => const ChatPage(),
      openInSecondScreen: false,
      icon: const Icon(Icons.chat),
    ),
  ];

  static List<Path> rootPaths = [
    Path(
      'Demo',
      '/demo',
      (context, state) => const DemoPage(),
      openInSecondScreen: false,
    ),
    Path(
      'Guide',
      '/guide',
      (context, state) => const GuidePage(),
      openInSecondScreen: false,
    ),
  ];

  static routers(ClintParam? clintParam) {
    return GoRouter(
        initialLocation: clintParam == null ? initInitial : initial,
        routes: [
          ShellRoute(
              pageBuilder:
                  (BuildContext context, GoRouterState state, Widget child) {
                return FadeTransitionPage(
                    key: state.pageKey, child: RootPage(child: child));
              },
              routes: [
                StatefulShellRoute(
                    builder: (BuildContext context, GoRouterState state,
                        StatefulNavigationShell navigationShell) {
                      return navigationShell;
                    },
                    branches: [
                      ...List.of(navPaths).map((path) {
                        return StatefulShellBranch(routes: <RouteBase>[
                          GoRoute(
                              name: path.name,
                              path: path.path,
                              builder: (context, state) {
                                return path.builder(context, state);
                              })
                        ]);
                      })
                    ],
                    navigatorContainerBuilder: (BuildContext context,
                        StatefulNavigationShell navigationShell,
                        List<Widget> children) {
                      return MainPage(
                          navigationShell: navigationShell, children: children);
                    })
              ]),
          ...List.of(rootPaths).map((path) {
            return GoRoute(
                name: path.name,
                path: path.path,
                pageBuilder: (context, state) {
                  return FadeTransitionPage(
                      key: state.pageKey, child: path.builder(context, state));
                });
          }),
        ]);
  }
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
