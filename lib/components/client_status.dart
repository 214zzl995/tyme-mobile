import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:provider/provider.dart';

import '../provider/client.dart';

class ClientStatus extends StatelessWidget {
  const ClientStatus({
    super.key,
    required this.child,
    this.onDisconnecting,
    this.onDisconnected,
    this.onConnecting,
    this.onFaulted,
  });

  /// onConnected
  final Widget child;

  final Widget? onDisconnecting;

  final Widget? onDisconnected;

  final Widget? onConnecting;

  final Widget? onFaulted;

  @override
  Widget build(BuildContext context) {


    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildStatus(context, context.watch<Client>().clientStatus));
  }

  Widget _buildDisconnected(BuildContext context) {
    return onDisconnected ??
        Container(
          key: const ValueKey('disconnected'),
        );
  }

  Widget _buildDisconnecting(BuildContext context) {
    return onDisconnecting ??
        Container(
          key: const ValueKey('disconnecting'),
        );
  }

  Widget _buildConnecting(BuildContext context) {
    return onConnecting ??
        Container(
          key: const ValueKey('connecting'),
        );
  }

  Widget _buildFaulted(BuildContext context) {
    return onFaulted ??
        Container(
          key: const ValueKey('faulted'),
        );
  }

  Widget _buildConnected(BuildContext context) {
    return child;
  }

  Widget _buildStatus(BuildContext context, MqttConnectionState status) {
    switch (status) {
      case MqttConnectionState.disconnected:
        return _buildDisconnected(context);
      case MqttConnectionState.disconnecting:
        return _buildDisconnecting(context);
      case MqttConnectionState.connecting:
        return _buildConnecting(context);
      case MqttConnectionState.connected:
        return _buildConnected(context);
      case MqttConnectionState.faulted:
        return _buildFaulted(context);
      default:
        return Container(
          key: const ValueKey('default'),
        );
    }
  }

  bool _isParentSliver(BuildContext context) {
    return context.widget.runtimeType == SliverWithKeepAliveWidget;
  }
}
