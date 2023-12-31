import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../components/dashed_line_message.dart';
import '../components/system_overlay_style_with_brightness.dart';
import '../data/chat_message.dart';
import '../data/client_param.dart';
import '../data/topic_chat_data.dart';
import '../provider/client.dart';

class ChatTopicPage extends StatefulWidget {
  const ChatTopicPage({Key? key, required this.topic}) : super(key: key);

  final SubscribeTopic topic;

  @override
  State<ChatTopicPage> createState() => _ChatTopicPageState();
}

class _ChatTopicPageState extends State<ChatTopicPage>
    with WidgetsBindingObserver {
  late final TextEditingController _inputController;

  final GlobalKey _centerKey = GlobalKey();
  final GlobalKey _appBarKey = GlobalKey();

  final int _preloadCount = 40;

  final ScrollController _messagesListController = ScrollController();

  late final TopicChatData _topicChatData = TopicChatData(
      widget.topic, context.read<Client>().messagesByTopicStream(widget.topic),
      preloadCount: _preloadCount);

  late double _anchor = 0;

  final double _bottomHeight = 80;

  late final int _initialReadIndex = _topicChatData.readIndex;

  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  final ValueNotifier<bool> _unreadCountIntercept = ValueNotifier<bool>(false);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state != AppLifecycleState.resumed) {
      context.read<Client>().currentTopic = null;
    } else {
      context.read<Client>().currentTopic = widget.topic;
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _inputController = TextEditingController();
    _inputController.addListener(() {
      setState(() {});
    });

    context.read<Client>().currentTopic = widget.topic;

    if (_topicChatData.pageInitialData.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        final minScrollExtent =
            -_messagesListController.position.minScrollExtent;

        final appBarContext = _appBarKey.currentContext as StatefulElement?;

        final bodyHeight = MediaQuery.of(context).size.height -
            (appBarContext!.size!.height +
                _bottomHeight +
                MediaQuery.of(context).padding.bottom) -
            0.01;

        if (minScrollExtent < bodyHeight && minScrollExtent > 0) {
          setState(() {
            _anchor = (minScrollExtent / bodyHeight) + 0.0000000000000001;
          });
        } else {
          setState(() {
            _anchor = 1;
          });
        }

        _messagesListController.jumpTo(0);

        _messagesListController.position.isScrollingNotifier.addListener(() {
          if (!_messagesListController.position.isScrollingNotifier.value) {
            debugPrint('scroll is stopped');
          } else {
            debugPrint('scroll is started');
          }
        });
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void deactivate() {
    super.deactivate();
    context.read<Client>().currentTopic = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messagesListController.dispose();
    _inputController.dispose();
    super.dispose();
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
    return SystemOverlayStyleWithBrightness(
      systemNavigationBarColor: Theme.of(context).colorScheme.onInverseSurface,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            key: _appBarKey,
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
                  _topicChatData.removeAll();
                  setState(() {
                    _anchor = 0;
                  });
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
              Expanded(child: _buildBody(context)),
              _buildBottom(context)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _topicChatData.emptyMessage,
        builder: (BuildContext context, empty, Widget? child) {
          return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: empty
                  ? _buildNoDataBody(context)
                  : _buildHasDataBody(context),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              });
        });
  }

  Widget _buildHasDataBody(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _topicChatData.noMore,
      builder: (BuildContext context, bool noMore, Widget? child) {
        return EasyRefresh(
          key: const ValueKey("HasDataBody"),
          clipBehavior: Clip.none,
          onRefresh: noMore ? null : _topicChatData.loadMore,
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
          child: child,
        );
      },
      child: Stack(children: [
        CustomScrollView(
          key: const ValueKey("MessagesList"),
          controller: _messagesListController,
          center: _centerKey,
          anchor: _anchor,
          slivers: [
            _buildPageMessagesList(context),
            SliverPadding(
              padding: EdgeInsets.zero,
              key: _centerKey,
            ),
            _buildMqttMessagesList(context),
          ],
        ),
        Positioned(bottom: 10, right: 10, child: _buildUnReadCount(context)),
      ]),
    );
  }

  Widget _buildUnReadCount(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: _messagesListController,
        builder: (context, child) {
          return ValueListenableBuilder<int>(
            valueListenable: _topicChatData.unreadCount,
            builder: (BuildContext context, int count, Widget? child) {
              return Selector<ScrollController, bool>(
                  builder:
                      (BuildContext context, bool scrollMax, Widget? child) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: _unreadCountIntercept,
                      builder: (BuildContext context, bool intercept,
                          Widget? child) {
                        debugPrint(
                            "count: $count, scrollMax: $scrollMax,intercept: $intercept,all: ${(count == 0 && scrollMax) || intercept}");
                        return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: (count == 0 && scrollMax) || intercept
                                ? const SizedBox(
                                    key: ValueKey("UnreadCountHide"),
                                  )
                                : ElevatedButton.icon(
                                    key: const ValueKey("UnreadCountShow"),
                                    onPressed: () {
                                      _messagesListController.animateTo(
                                        _messagesListController
                                            .position.maxScrollExtent,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    },
                                    icon: const Icon(
                                        Icons.arrow_downward_outlined),
                                    label: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        child: SizedBox(
                                          key: ValueKey(count),
                                          width: 40,
                                          child: Center(
                                            child: Text(
                                              count == 0
                                                  ? "Down"
                                                  : count.toString(),
                                              key: ValueKey(count),
                                            ),
                                          ),
                                        ),
                                        transitionBuilder: (child, animation) {
                                          return ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          );
                                        }),
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
                    );
                  },
                  selector: (BuildContext context,
                          ScrollController scrollController) =>
                      (_messagesListController.position.hasContentDimensions &&
                          _messagesListController.offset >=
                              _messagesListController
                                  .position.maxScrollExtent) ||
                      !_messagesListController.position.hasContentDimensions);
            },
          );
        });
  }

  Widget _buildNoDataBody(BuildContext context) {
    return Column(
      key: const ValueKey("NoDataBody"),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          "assets/lottie/empty_message.json",
          width: 300,
          height: 300,
          fit: BoxFit.cover,
        ),
        const SizedBox(
          height: 20,
        ),
        Text(
          "No messages...",
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildPageMessagesList(BuildContext context) {
    return StreamProvider<List<(int, ChatMessage)>>.value(
      initialData: _topicChatData.pageInitialData,
      value: _topicChatData.pageMessageStream,
      child: Consumer<List<(int, ChatMessage)>>(
        builder: (context, messages, child) {
          return SliverList.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _buildMessageCard(context, message.$2, message.$1,
                  storingData: true);
            },
          );
        },
      ),
    );
  }

  Widget _buildMqttMessagesList(BuildContext context) {
    return StreamProvider<List<(int, ChatMessage)>>.value(
      initialData: const [],
      value: _topicChatData.mqttMessageStream,
      child: Consumer<List<(int, ChatMessage)>>(
        builder: (context, messages, child) {
          if (_messagesListController.position.hasContentDimensions &&
              _messagesListController.offset + 200 >
                  (_messagesListController.position.maxScrollExtent) &&
              _lifecycleState == AppLifecycleState.resumed) {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
              _unreadCountIntercept.value = true;
              await _messagesListController.animateTo(
                _messagesListController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            });
          }

          return SliverList.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _buildMessageCard(context, message.$2, message.$1);
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageCard(
      BuildContext context, ChatMessage message, int hiveIndex,
      {bool storingData = false}) {
    ValueNotifier<bool> expandShow = ValueNotifier<bool>(false);
    return VisibilityDetector(
      key: ValueKey(hiveIndex),
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction == 0) {
          return;
        }
        if (!_messagesListController.position.isScrollingNotifier.value) {
          _unreadCountIntercept.value = false;
        }
        _topicChatData.changeReadIndex(hiveIndex);
      },
      child: Column(
        children: [
          Align(
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
                  padding: const EdgeInsets.only(
                      right: 10, left: 10, bottom: 2, top: 2),
                  margin: const EdgeInsets.only(
                      bottom: 10, left: 8, right: 8, top: 8),
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
          if (hiveIndex == _initialReadIndex && storingData)
            const DashedLineMessage(),
        ],
      ),
    );
  }

  Widget _buildBottom(BuildContext context) {
    return Container(
      height: _bottomHeight + MediaQuery.of(context).padding.bottom,
      color: Theme.of(context).colorScheme.onInverseSurface,
      child: Padding(
        padding: EdgeInsets.only(
            top: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            left: 8,
            right: 8),
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
}

extension DateTimeFormatting on DateTime {
  String toCustomString() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}-${minute.toString().padLeft(2, '0')}-${second.toString().padLeft(2, '0')}';
  }
}
