import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routers.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: child,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (index) {
          GoRouter.of(context).go(TymeRouteConfiguration.paths[index].path);
        },
        selectedIndex: TymeRouteConfiguration.paths.indexWhere((element) =>
            element.path ==
            GoRouter.of(context).routeInformationProvider.value.uri.path),
        destinations: [
          ...List.of(TymeRouteConfiguration.paths).map((path) {
            return NavigationDestination(
              icon: const Icon(Icons.home),
              label: path.name,
            );
          })
        ],
      ),
    );
    return child;
  }
}
