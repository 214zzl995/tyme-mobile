import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routers.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: child,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (index) {
          GoRouter.of(context).go(TymeRouteConfiguration.navPaths[index].path);
        },
        selectedIndex: TymeRouteConfiguration.navPaths.indexWhere((element) =>
            element.path ==
            GoRouter.of(context).routeInformationProvider.value.uri.path),
        destinations: [
          ...List.of(TymeRouteConfiguration.navPaths).map((path) {
            return NavigationDestination(
              icon: path.icon ?? const Icon(Icons.waving_hand),
              label: path.name,
            );
          })
        ],
      ),
    );
  }
}
