import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../components/detect_lifecycle.dart';
import '../data/chat_message.dart';
import '../data/clint_param.dart';
import '../data/topic_read_index.dart';
import '../provider/clint.dart';

class ChatTopicPage extends StatefulWidget {
  const ChatTopicPage({Key? key, required this.topic}) : super(key: key);

  final SubscribeTopic topic;

  @override
  State<ChatTopicPage> createState() => _ChatTopicPageState();
}

class _ChatTopicPageState extends State<ChatTopicPage> {
  final _listenable = IndicatorStateListenable();
  late final TextEditingController _inputController;

  bool _shrinkWrap = false;
  double? _viewportDimension;

  int preloadCount = 40;

  ScrollController messagesListController = ScrollController();

  late TopicReadIndex topicReadIndex = TopicReadIndex(
      widget.topic, context.read<Clint>().messagesByTopicStream(widget.topic),
      preloadCount: preloadCount);

  late int initialScrollIndex =
      topicReadIndex.readIndex - topicReadIndex.skipCount;

  double currentPosition = 0;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _inputController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messagesListController
          .jumpTo(messagesListController.position.maxScrollExtent);
    });
    _listenable.addListener(_onHeaderChange);
  }

  @override
  void dispose() {
    _listenable.removeListener(_onHeaderChange);
    _inputController.dispose();
    super.dispose();
  }

  void _onHeaderChange() {
    final state = _listenable.value;
    if (state != null) {
      final position = state.notifier.position;
      _viewportDimension ??= position.viewportDimension;
      final shrinkWrap = state.notifier.position.maxScrollExtent == 0;
      if (_shrinkWrap != shrinkWrap &&
          _viewportDimension == position.viewportDimension) {
        setState(() {
          _shrinkWrap = shrinkWrap;
        });
      }
    }
  }

  void _onSend() {
    if (_inputController.text.isEmpty) {
      return;
    }
    _inputController.clear();
    Future(() {
      PrimaryScrollController.of(context).jumpTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
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
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                topicReadIndex.removeAll();
              },
            )
          ],
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
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            Expanded(
              child: EasyRefresh(
                clipBehavior: Clip.none,
                onRefresh: () {
                  topicReadIndex.loadMore();
                },
                // onLoad: () {},
                footer: ListenerFooter(
                  listenable: _listenable,
                  triggerOffset: 0,
                  clamping: false,
                ),
                header: BuilderHeader(
                    triggerOffset: 40,
                    clamping: false,
                    position: IndicatorPosition.above,
                    infiniteOffset: null,
                    processedDuration: Duration.zero,
                    builder: (context, state) {
                      return Stack(
                        children: [
                          SizedBox(
                            height: state.offset,
                            width: double.infinity,
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              alignment: Alignment.center,
                              width: double.infinity,
                              height: 40,
                              child: SpinKitCircle(
                                size: 24,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                        ],
                      );
                    }),
                child: _buildMessagesList(context),
              ),
            ),
            _buildBottom(context)
          ],
        ),
      ),
    );
  }

  Widget _buildBottom(BuildContext context) {
    return Container(
      height: 100,
      color: Theme.of(context).colorScheme.onInverseSurface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              color: Theme.of(context).colorScheme.primary,
              icon: const Icon(Icons.add_circle_outline),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: () {},
              color: Theme.of(context).colorScheme.primary,
              icon: const Icon(Icons.tag_faces),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _inputController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    prefixIcon: const Icon(Icons.abc),
                    suffixIcon: IconButton(
                      onPressed: () {
                        if (_inputController.text.isNotEmpty) {
                          _onSend();
                        }
                      },
                      icon: Icon(_inputController.text.isNotEmpty
                          ? Icons.send
                          : Icons.keyboard_voice_outlined),
                    ),
                  ),
                  onSubmitted: (_) => _onSend(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    return StreamProvider<List<(int, ChatMessage)>>(
      initialData: topicReadIndex.initialData,
      create: (BuildContext context) => topicReadIndex.messageStream,
      child: Consumer<List<(int, ChatMessage)>>(
        builder: (context, messages, child) {
          if (messages.isEmpty) {
            return const Center(
              child: Text('No Message'),
            );
          }
          return DetectLifecycleScrollTo(
            build:
                (BuildContext context, AppLifecycleState state, Widget? child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {});
              return child!;
            },
            child: ListView.builder(
              controller: messagesListController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageCard(context, message.$2, message.$1);
              },
              reverse: false,
              shrinkWrap: _shrinkWrap,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageCard(
      BuildContext context, ChatMessage message, int hiveIndex) {
    ValueNotifier<bool> expandShow = ValueNotifier<bool>(false);
    return VisibilityDetector(
      key: ValueKey(hiveIndex),
      onVisibilityChanged: (VisibilityInfo info) {
        topicReadIndex.changeReadIndex(hiveIndex);
      },
      child: Align(
        alignment: message.mine ? Alignment.centerRight : Alignment.centerLeft,
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
              padding:
                  const EdgeInsets.only(right: 10, left: 10, bottom: 2, top: 2),
              margin:
                  const EdgeInsets.only(bottom: 10, left: 8, right: 8, top: 8),
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
                  Text(hiveIndex.toString()),
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
    );
  }
}

extension DateTimeFormatting on DateTime {
  String toCustomString() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}-${minute.toString().padLeft(2, '0')}-${second.toString().padLeft(2, '0')}';
  }
}
