import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:tyme/provider/client.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        key: const PageStorageKey("home_page_scroll_view"),
        controller: ScrollController(),
        slivers: <Widget>[
          const SliverAppBar.large(
            leading: Icon(Icons.home),
            title: Text('Home'),
          ),
          _buildBody(context)
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Selector<Client, MqttConnectionState>(
      selector: (_, client) => client.clientStatus,
      builder: (context, status, child) {
        return SliverAnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStatus(context, status));
      },
    );
  }

  Widget _buildDisconnected(BuildContext context) {
    return SliverFillRemaining(
        hasScrollBody: false,
        key: const ValueKey('disconnected'),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 120.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Lottie.asset(
                'assets/lottie/client_disconnect.json',
                width: 250,
                height: 250,
                fit: BoxFit.cover,
                repeat: true,
              ),
              Text(
                'Disconnected',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                'Please connect to the server',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(
                height: 30,
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Connect'),
              )
            ],
          ),
        ));
  }

  Widget _buildRunning(BuildContext context, [disconnecting = false]) {
    return SliverFillRemaining(
      hasScrollBody: false,
      key: const ValueKey('connecting'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 5,
            width: 250,
            child: LinearProgressIndicator(
              borderRadius: const BorderRadius.all(Radius.circular(5)),
              backgroundColor: disconnecting
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.primaryContainer,
              color: disconnecting
                  ? Theme.of(context).colorScheme.error.withOpacity(0.5)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          Text(
            disconnecting ? 'DisConnecting...' : 'Connecting...',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
        //条形进度条
      ),
    );
  }

  Widget _buildFaulted(BuildContext context) {
    return const SliverFillRemaining(
        hasScrollBody: false,
        key: ValueKey('faulted'),
        child: Center(
          child: Text('Faulted'),
        ));
  }

  Widget _buildConnected(BuildContext context) {
    return const SliverFillRemaining(
        hasScrollBody: false,
        key: ValueKey('connected'),
        child: Center(
          child: Text('Connected'),
        ));
  }

  Widget _buildStatus(BuildContext context, MqttConnectionState status) {
    switch (status) {
      case MqttConnectionState.disconnected:
        return _buildDisconnected(context);
      case MqttConnectionState.disconnecting:
        return _buildRunning(context, true);
      case MqttConnectionState.connecting:
        return _buildRunning(context);
      case MqttConnectionState.connected:
        return _buildConnected(context);
      case MqttConnectionState.faulted:
        return _buildFaulted(context);
      default:
        return const SliverToBoxAdapter(
          key: ValueKey('default'),
        );
    }
  }

  Widget _buildServerCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {},
        child: const Card(
          child: ListTile(
            leading: Icon(Icons.home),
            title: Text('Home Page'),
          ),
        ),
      ),
    );
  }
}
