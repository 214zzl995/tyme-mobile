import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:provider/provider.dart';
import 'package:tyme/clint.dart';

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
          StreamProvider<List<MqttReceivedMessage<MqttMessage>>>(
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
          ),
        ],
      ),
    );
  }
}
