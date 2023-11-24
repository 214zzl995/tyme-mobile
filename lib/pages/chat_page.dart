import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:provider/provider.dart';
import 'package:tyme/data/clint.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    return Scaffold(
      body: CustomScrollView(
        controller: scrollController,
        slivers: <Widget>[
          const SliverAppBar.large(
            leading: Icon(Icons.chat),
            title: Text('Chat'),
          ),
          SliverToBoxAdapter(
              child: Center(
                  child: Selector<Clint, MqttConnectionState>(
                      builder: (context, state, child) {
                        return _connecting(context);
                      },
                      selector: (context, state) => state.clintStatus))),
        ],
      ),
    );
  }

  Widget _connecting(BuildContext context) {
    return Column(
      children: [
        SizedBox(
            height: 300,
            width: 300,
            child: Lottie.asset(
              'assets/lottie/chat_connecting.json',
              fit: BoxFit.cover,
              repeat: true,
            )),
        const SizedBox(
          height: 5,
          width: 200,
          child: LinearProgressIndicator(
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
        ),
      ],
      //条形进度条
    );
  }

  Widget _disconnected(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.error),
        Text('MQtt Disconnected'),
      ],
    );
  }

  Widget _chatList(BuildContext context, ScrollController scrollController) {
    return StreamProvider<List<MqttReceivedMessage<MqttMessage>>>(
      initialData: const [],
      create: (BuildContext context) =>
          context.read<Clint>().msgByTopic('system/#'),
      child: Consumer<List<MqttReceivedMessage<MqttMessage>>>(
        builder: (context, messages, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients) {
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
          return SliverList(
            key: const PageStorageKey("chat_page_scroll_view"),
            delegate: SliverChildListDelegate(
              <Widget>[
                ...messages.mapIndexed(
                  (index, message) => ListTile(
                    title: Text('Item $index'),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
