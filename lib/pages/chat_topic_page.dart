import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:tyme/provider/clint.dart';
import 'package:tyme/provider/topic_read_index.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../components/detect_lifecycle.dart';
import '../data/chat_message.dart';
import '../data/clint_param.dart';

// 滚动条设置到某个位置
// https://stackoverflow.com/questions/60528815/flutter-how-to-scroll-to-a-specific-item-position-in-sliverlist

class ChatTopicPage extends StatelessWidget {
  const ChatTopicPage({Key? key, required this.topic}) : super(key: key);

  final SubscribeTopic topic;

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    final autoScrollController = AutoScrollController(
      viewportBoundaryGetter: () =>
          Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
    );

    return Scaffold(
      body: CustomScrollView(
        controller: autoScrollController,
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
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
                  topic.topic,
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
          ),
          Selector<Clint, MqttConnectionState>(
            builder: (context, state, child) {
              if (state == MqttConnectionState.connected) {
                return _chatList(
                    context, scrollController, autoScrollController);
              } else {
                return SliverToBoxAdapter(
                    child: Center(child: _connecting(context)));
              }
            },
            selector: (context, state) => state.clintStatus,
          ),
          // 底部太空了 添加一个快捷回复的框 将 ‘+’ 或 ‘#’ 转换为 ‘$’ 添加设置项设置自动转换逻辑 在此输入框输入无法配置topic 只能保证订阅了此topic的人能够收到消息
          // 还需要添加一个显示未读的 按钮等 当存在未读时 显示未读的数字 当不存在未读时 显示到达底部按钮
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await autoScrollController.scrollToIndex(50,
              preferPosition: AutoScrollPosition.begin);

          autoScrollController.highlight(50);
        },
        child: const Text("Test"),
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

  Widget _chatList(BuildContext context, ScrollController scrollController,
      AutoScrollController autoScrollController) {
    final initialData = context.read<Clint>().getTopicInitialData(topic);
    return Provider(
        create: (_) => TopicReadIndex(topic),
        child: StreamProvider<List<(int, ChatMessage)>>(
          initialData: initialData,
          create: (BuildContext context) =>
              context.read<Clint>().msgByTopic(topic, initialData: initialData),
          child: Consumer<List<(int, ChatMessage)>>(
            builder: (context, messages, child) {
              // 需要判断是否之前已经读完 如果之前已经读完 直接跳转 到最新的消息 可以考虑直接获取 TopicReadIndex 的index
              if (messages.length == initialData.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  //定位到未读Index
                  // scrollController
                  //     .jumpTo(scrollController.position.maxScrollExtent);
                });
              }
              if (messages.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Text('No Message'),
                  ),
                );
              }
              return DetectLifecycleScrollTo(
                build: (BuildContext context, AppLifecycleState state,
                    Widget? child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (scrollController.hasClients &&
                        state == AppLifecycleState.resumed) {
                      scrollController.animateTo(
                        scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.bounceIn,
                      );
                    }
                  });
                  return child!;
                },
                child: SliverList(
                  delegate: SliverChildListDelegate(
                    <Widget>[
                      // 前面加个空白的占位的Widget 不然太空了
                      ...messages.map((message) => _buildMessageCard(context,
                          autoScrollController, message.$2, message.$1))
                    ],
                  ),
                ),
              );
            },
          ),
        ));
  }

  Widget _buildMessageCard(
      BuildContext context,
      AutoScrollController autoScrollController,
      ChatMessage message,
      int index) {
    ValueNotifier<bool> expandShow = ValueNotifier<bool>(false);
    TopicReadIndex topicReadIndex = context.read<TopicReadIndex>();
    return AutoScrollTag(
      key: ValueKey("scroll$index"),
      controller: autoScrollController,
      index: index,
      highlightColor: Colors.black.withOpacity(0.1),
      child: VisibilityDetector(
        key: ValueKey(index),
        onVisibilityChanged: (VisibilityInfo info) {
          topicReadIndex.changeReadIndex(index);
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
}

extension DateTimeFormatting on DateTime {
  String toCustomString() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}-${minute.toString().padLeft(2, '0')}-${second.toString().padLeft(2, '0')}';
  }
}
