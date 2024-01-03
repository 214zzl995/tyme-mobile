import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:provider/provider.dart';
import '../components/system_overlay_style_with_brightness.dart';
import '../provider/client.dart';
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
    return SystemOverlayStyleWithBrightness(
        systemNavigationBarColor: ElevationOverlay.colorWithOverlay(
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceTint,
            3),
        child: Scaffold(
          body: AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          ),
          bottomNavigationBar: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildMqttStateBar(context),
              NavigationBar(
                elevation: 3,
                onDestinationSelected: (index) {
                  GoRouter.of(context)
                      .go(TymeRouteConfiguration.navPaths[index].path);
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
            ],
          ),
        ));
  }

  Widget _buildMqttStateBar(BuildContext context) {
    const statusBarHeight = 40.0;
    return Positioned(
      top: -statusBarHeight - 5,
      left: 5,
      child: Selector<Client, MqttConnectionState>(
        builder:
            (BuildContext context, MqttConnectionState value, Widget? child) {
          return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: value == MqttConnectionState.connected
                  ? Container(
                      height: 0,
                      key: const ValueKey("BottomNavigationBarHide"),
                    )
                  : Container(
                      key: const ValueKey("BottomNavigationBarShow"),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ElevationOverlay.colorWithOverlay(
                            Theme.of(context).colorScheme.surface,
                            Theme.of(context).colorScheme.surfaceTint,
                            3),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      width: 150,
                      height: statusBarHeight,
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: getStatusColor(context, value),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: getStatusIcon(context, value),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            getStatusText(context, value),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: getStatusColor(context, value)),
                          )
                        ],
                      ),
                    ),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1), // Start position
                    end: Offset.zero, // End position
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              });
        },
        selector: (BuildContext context, Client client) => client.clientStatus,
      ),
    );
  }

  getStatusIcon(BuildContext context, MqttConnectionState status) {
    switch (status) {
      case MqttConnectionState.connected:
        return const Icon(
          Icons.check_circle_outline,
        );
      case MqttConnectionState.connecting:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        );
      case MqttConnectionState.disconnected:
        return Container();
      default:
        return Container();
    }
  }

  Color getStatusColor(BuildContext context, MqttConnectionState status) {
    switch (status) {
      case MqttConnectionState.connected:
        return Theme.of(context).colorScheme.onPrimaryContainer;
      case MqttConnectionState.connecting:
        return Theme.of(context).colorScheme.onPrimaryContainer;
      case MqttConnectionState.disconnected:
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.error;
    }
  }

  String getStatusText(BuildContext context, MqttConnectionState status) {
    switch (status) {
      case MqttConnectionState.connected:
        return "Connected";
      case MqttConnectionState.connecting:
        return "Connecting...";
      case MqttConnectionState.disconnected:
        return "Disconnected";
      default:
        return status.name;
    }
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
