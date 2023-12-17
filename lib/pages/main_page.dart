import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routers.dart';
import 'package:collection/collection.dart';

class MainPage extends StatelessWidget {
  const MainPage({
    required this.navigationShell,
    required this.children,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  /// The children (branch Navigators) to display in a custom container
  /// ([AnimatedBranchContainer]).
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBranchContainer(
        currentIndex: navigationShell.currentIndex,
        children: children,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (index) {
          GoRouter.of(context).go(TymeRouteConfiguration.navPaths[index].path);
        },
        selectedIndex: getSelectedIndex(context),
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

  int getSelectedIndex(BuildContext context) {
    int index = TymeRouteConfiguration.navPaths.indexWhere((element) =>
        element.path ==
        GoRouter.of(context).routeInformationProvider.value.uri.path);
    return index == -1 ? navigationShell.currentIndex : index;
  }
}

class AnimatedBranchContainer extends StatelessWidget {
  /// Creates a AnimatedBranchContainer
  const AnimatedBranchContainer(
      {super.key, required this.currentIndex, required this.children});

  /// The index (in [children]) of the branch Navigator to display.
  final int currentIndex;

  /// The children (branch Navigators) to display in this container.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: children.mapIndexed(
      (int index, Widget navigator) {
        return AnimatedOpacity(
          opacity: index == currentIndex ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: _branchNavigatorWrapper(index, navigator),
        );
      },
    ).toList());
  }

  Widget _branchNavigatorWrapper(int index, Widget navigator) => IgnorePointer(
        ignoring: index != currentIndex,
        child: TickerMode(
          enabled: index == currentIndex,
          child: navigator,
        ),
      );
}
