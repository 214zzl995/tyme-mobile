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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.read<Client>().restart();
          },
          child: const Icon(Icons.refresh),
        ));
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
    return const SliverFillRemaining(
      hasScrollBody: false,
      key: ValueKey('disconnected'),
      child: Center(
        child: Text('Disconnected'),
      ),
    );
  }

  Widget _buildDisconnecting(BuildContext context) {
    return const SliverFillRemaining(
        hasScrollBody: false,
        key: ValueKey('disconnecting'),
        child: Center(
          child: Text('Disconnecting'),
        ));
  }

  Widget _buildConnecting(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      key: const ValueKey('connecting'),
      child: Container(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
                height: 300,
                width: 300,
                child: Lottie.asset(
                  'assets/lottie/chat_connecting.json',
                  fit: BoxFit.cover,
                  repeat: true,
                )),
            Text(
              'Connecting',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(
              height: 10,
            ),
            const SizedBox(
              height: 5,
              width: 200,
              child: LinearProgressIndicator(
                borderRadius: BorderRadius.all(Radius.circular(5)),
              ),
            ),
          ],
          //条形进度条
        ),
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
    return SliverList(
      delegate: SliverChildListDelegate(
        <Widget>[
          _buildServerCard(context),
          _buildServerCard(context),
          _buildServerCard(context),
          _buildServerCard(context),
          _buildServerCard(context),
          _buildServerCard(context),
        ],
      ),
    );
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
