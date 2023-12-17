import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tyme/data/clint_param.dart';
import 'package:tyme/pages/chat_page.dart';
import 'package:tyme/pages/chat_topic_page.dart';
import 'package:tyme/pages/demo_page.dart';
import 'package:tyme/pages/guide_page.dart';
import 'package:tyme/pages/home_page.dart';
import 'package:tyme/pages/main_page.dart';
import 'package:tyme/pages/root_page.dart';
import 'package:tyme/pages/settings_page.dart';

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
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> rootParentNavigatorKey =
      GlobalKey<NavigatorState>();

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
    Path(
      'Settings',
      '/settings',
      (context, state) => const SettingsPage(),
      openInSecondScreen: false,
      icon: const Icon(Icons.settings),
    ),
  ];

  static List<Path> navDetailPaths = [
    Path(
      'ChatTopic',
      '/chat_topic',
      (context, state) {
        SubscribeTopic? topic = state.extra as SubscribeTopic?;
        if (topic == null) {
          // 获取state.uri 传递的topic 和qos
          final uri = state.uri;
          final String? topicStr = uri.queryParameters['topic'];
          final String? qosStr = uri.queryParameters['qos'];

          if (topicStr != null && qosStr != null) {
            topic = SubscribeTopic(topicStr, int.parse(qosStr));
          } else {
            // 都不存在回Chat
            GoRouter.of(context).goNamed("Chat");
          }
        }
        return ChatTopicPage(topic: topic!);
      },
      openInSecondScreen: false,
      icon: const Icon(Icons.settings),
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
              navigatorKey: rootParentNavigatorKey,
              pageBuilder:
                  (BuildContext context, GoRouterState state, Widget child) {
                return FadeTransitionPage(
                    key: state.pageKey, child: RootPage(child: child));
              },
              routes: [
                StatefulShellRoute(
                    parentNavigatorKey: rootParentNavigatorKey,
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
                    }),
                ...List.of(navDetailPaths).map((path) {
                  return GoRoute(
                      parentNavigatorKey: rootParentNavigatorKey,
                      name: path.name,
                      path: path.path,
                      pageBuilder: (context, state) {
                        return FadeTransitionPage(
                          key: state.pageKey,
                          child: path.builder(context, state),
                        );
                      });
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
  FadeTransitionPage({
    required LocalKey super.key,
    required super.child,
  }) : super(
            transitionsBuilder: (BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                    Widget child) =>
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

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  static const Curve _curve = Cubic(1, .19, 0, .81);
}
