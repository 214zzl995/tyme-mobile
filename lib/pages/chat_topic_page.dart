import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:provider/provider.dart';
import 'package:tyme/provider/clint.dart';
import '../components/detect_lifecycle.dart';
import '../data/chat_message.dart';

class ChatTopicPage extends StatelessWidget {
  const ChatTopicPage({Key? key, required this.topic}) : super(key: key);

  final String topic;

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
          Selector<Clint, MqttConnectionState>(
            builder: (context, state, child) {
              if (state == MqttConnectionState.connected) {
                return _chatList(context, scrollController);
              } else {
                return SliverToBoxAdapter(
                    child: Center(child: _connecting(context)));
              }
            },
            selector: (context, state) => state.clintStatus,
          ),
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
    return StreamProvider<List<ChatMessage>>(
      initialData: const [],
      create: (BuildContext context) =>
          context.read<Clint>().msgByTopic('system/#'),
      child: Consumer<List<ChatMessage>>(
        builder: (context, messages, child) {
          return DetectLifecycleScrollTo(
            build:
                (BuildContext context, AppLifecycleState state, Widget? child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (scrollController.hasClients &&
                    GoRouter.of(context)
                            .routeInformationProvider
                            .value
                            .uri
                            .path ==
                        "/chat" &&
                    state == AppLifecycleState.resumed) {
                  scrollController.animateTo(
                    scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
              return child!;
            },
            child: SliverList(
              key: const PageStorageKey("chat_page_scroll_view"),
              delegate: SliverChildListDelegate(
                <Widget>[
                  ...messages.mapIndexed(
                      (index, message) => _buildMessageCard(context, message))
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context, ChatMessage message) {
    return Align(
      alignment: message.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
            color: message.mine
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant)),
        width: 270,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 10, left: 8, right: 8),
        child: MarkdownBody(data: message.content.raw),
      ),
    );
  }
}
