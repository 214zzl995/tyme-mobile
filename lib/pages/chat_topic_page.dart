import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:provider/provider.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:tyme/provider/clint.dart';
import 'package:tyme/data/topic_read_index.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../components/detect_lifecycle.dart';
import '../data/chat_message.dart';
import '../data/clint_param.dart';

class ChatTopicPage extends StatefulWidget {
  const ChatTopicPage({Key? key, required this.topic}) : super(key: key);

  final SubscribeTopic topic;

  @override
  State<StatefulWidget> createState() => ChatTopicPageState();
}

class ChatTopicPageState extends State<ChatTopicPage> {
  BuildContext? _chatListCtx;

  GlobalKey appBarKey = GlobalKey();
  GlobalKey readIndexKey = GlobalKey();

  ScrollController scrollController = ScrollController();

  late SliverObserverController observerController;

  late TopicReadIndex topicReadIndex = TopicReadIndex(widget.topic);

  late List<(int, ChatMessage)> initialData = topicReadIndex.topicInitialData;

  @override
  void initState() {
    observerController = SliverObserverController(controller: scrollController);

    observerController.initialIndex = topicReadIndex.readIndex;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      observerController.dispatchOnceObserve(
        sliverContext: _chatListCtx!,
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SliverViewObserver(
      controller: observerController,
      sliverContexts: () {
        return [
          if (_chatListCtx != null) _chatListCtx!,
        ];
      },
      autoTriggerObserveTypes: const [
        ObserverAutoTriggerObserveType.scrollEnd,
      ],
      triggerOnObserveType: ObserverTriggerOnObserveType.directly,
      onObserveAll: (resultMap) {},
      child: Scaffold(
        body: CustomScrollView(
          controller: scrollController,
          slivers: <Widget>[
            _buildAppBar(context),
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            observerController.animateTo(
                index: 105,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
                sliverContext: _chatListCtx!,
                offset: calcPersistentHeaderExtent);
          },
          child: const Icon(Icons.arrow_downward),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      key: appBarKey,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          GoRouter.of(context).goNamed("Chat");
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mark_chat_unread_outlined),
          const SizedBox(
            width: 10,
          ),
          Text(
            widget.topic.topic,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.8), // 这里设置你想要的高度
        child: Divider(
          height: 0.8,
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withOpacity(0.2), // 这里设置你想要的颜色
        ),
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
    return StreamProvider<List<(int, ChatMessage)>>(
      initialData: initialData,
      create: (BuildContext context) => context
          .read<Clint>()
          .msgByTopic(widget.topic, initialData: initialData),
      child: Consumer<List<(int, ChatMessage)>>(
        builder: (context, messages, child) {
          if (messages.isEmpty) {
            return const SliverToBoxAdapter(
              child: Center(
                child: Text('No Message'),
              ),
            );
          }
          return DetectLifecycleScrollTo(
            build:
                (BuildContext context, AppLifecycleState state, Widget? child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {});
              return child!;
            },
            child: SliverList(
              delegate: SliverChildBuilderDelegate((ctx, index) {
                _chatListCtx ??= ctx;
                final message = messages[index];
                final key = message.$1 == topicReadIndex.readIndex
                    ? readIndexKey
                    : null;
                return _buildMessageCard(context, message.$2, message.$1,
                    key: key);
              }, childCount: messages.length),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageCard(
      BuildContext context, ChatMessage message, int dbIndex,
      {GlobalKey? key}) {
    ValueNotifier<bool> expandShow = ValueNotifier<bool>(false);
    return Container(
      key: key,
      child: VisibilityDetector(
        key: ValueKey(dbIndex),
        onVisibilityChanged: (VisibilityInfo info) {
          topicReadIndex.changeReadIndex(dbIndex);
        },
        child: Align(
          alignment:
              message.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {
              expandShow.value = !expandShow.value;

              if (expandShow.value) {
                Future.delayed(const Duration(milliseconds: 2000), () {
                  expandShow.value = false;
                });
              }
            },
            onLongPressStart: (details) {
              expandShow.value = true;
            },
            onLongPressEnd: (details) {
              Future.delayed(const Duration(milliseconds: 500), () {
                expandShow.value = false;
              });
            },
            child: Container(
                decoration: BoxDecoration(
                    color: message.mine
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : Theme.of(context).colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant)),
                width: 270,
                padding: const EdgeInsets.only(right: 10, left: 10, bottom: 2),
                margin: const EdgeInsets.only(bottom: 10, left: 8, right: 8),
                child: Column(
                  children: [
                    ValueListenableBuilder(
                        valueListenable: expandShow,
                        builder:
                            (BuildContext context, bool show, Widget? child) {
                          return Row(
                            children: [
                              Text(
                                show ? message.topic.topic : "",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline),
                              ),
                            ],
                          );
                        }),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(dbIndex.toString()),
                    MarkdownBody(data: message.content.raw),
                    const SizedBox(
                      height: 10,
                    ),
                    ValueListenableBuilder(
                        valueListenable: expandShow,
                        builder:
                            (BuildContext context, bool show, Widget? child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                  show
                                      ? DateTime.fromMillisecondsSinceEpoch(
                                              message.timestamp)
                                          .toCustomString()
                                      : "",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline)),
                            ],
                          );
                        }),
                  ],
                )),
          ),
        ),
      ),
    );
  }

  double calcPersistentHeaderExtent(double offset) {
    return ObserverUtils.calcPersistentHeaderExtent(
      key: appBarKey,
      offset: offset,
    );
  }
}

extension DateTimeFormatting on DateTime {
  String toCustomString() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}-${minute.toString().padLeft(2, '0')}-${second.toString().padLeft(2, '0')}';
  }
}
