import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tyme/data/client_param.dart';

import '../components/slide_fade_transition.dart';
import '../components/system_overlay_style_with_brightness.dart';
import '../provider/client.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            leading: const Icon(Icons.chat),
            title: const Text('Chat'),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 10),
                child: IconButton.filledTonal(
                    onPressed: () {
                      _buildAddTopicDialog(context, (value) {
                        context.read<Client>().subscriptionTopic(value);
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline)),
              )
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withOpacity(0.2),
                    width: 0.8,
                  ),
                ),
              ),
            ),
          ),
          Selector<Client, List<SubscribeTopic>>(
            builder: (BuildContext context,
                List<SubscribeTopic> subscribeTopics, Widget? child) {
              return SliverList(
                delegate: SliverChildListDelegate(
                  <Widget>[
                    ...subscribeTopics
                        .map((topic) => _buildTopicItemH(context, topic))
                  ],
                ),
              );
            },
            selector: (context, client) => client.clientParam.subscribeTopics,
          ),
        ],
      ),
    );
  }

  Widget _buildTopicItemH(BuildContext context, SubscribeTopic topic) {
    GlobalKey key = GlobalKey();
    const popToolsWidth = 150.0;
    const popToolsHeight = 50.0;
    const topicListHeight = 70.0;
    const popToolsRadio = 10.0;

    final popToolsButtonStyle = TextButton.styleFrom(
        padding: const EdgeInsets.all(5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(popToolsRadio)),
        foregroundColor:
            Theme.of(context).colorScheme.onInverseSurface.withOpacity(0.5));
    final popToolsTextStyle =
        TextStyle(color: Theme.of(context).colorScheme.onInverseSurface);

    final menuController = MenuController();

    return MenuAnchor(
        controller: menuController,
        clipBehavior: Clip.none,
        alignmentOffset: Offset(
            MediaQuery.of(context).size.width / 2 - popToolsWidth / 2,
            -(popToolsHeight + topicListHeight)),
        style: MenuStyle(
            backgroundColor: MaterialStateProperty.all(Colors.transparent),
            shadowColor: MaterialStateProperty.all(Colors.transparent),
            elevation: MaterialStateProperty.all(0),
            padding: MaterialStateProperty.all(EdgeInsets.zero)),
        menuChildren: <Widget>[
          SlideFadeTransition(
            child: CustomPaint(
              painter: BubblePainter(
                  borderRadius: popToolsRadio,
                  bubbleColor: Theme.of(context).colorScheme.inverseSurface),
              child: Container(
                width: popToolsWidth,
                height: popToolsHeight,
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        child: TextButton(
                            style: popToolsButtonStyle,
                            onPressed: () {
                              context
                                  .read<Client>()
                                  .unSubscriptionTopic(topic)
                                  .then((value) => menuController.close());
                            },
                            child: Text(
                              "Delete",
                              style: popToolsTextStyle,
                            ))),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 10),
                      child: VerticalDivider(
                        width: 1,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    Expanded(
                        child: TextButton(
                            style: popToolsButtonStyle,
                            onPressed: () {},
                            child: Text("Update", style: popToolsTextStyle)))
                  ],
                ), // 在气泡中添加一些文本
              ),
            ),
          ),
        ],
        builder:
            (BuildContext context, MenuController controller, Widget? child) {
          return SizedBox(
            height: topicListHeight,
            key: key,
            child: InkWell(
              onTap: () {
                pushChatTopic(context, topic);
              },
              onLongPress: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withOpacity(0.2),
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_chat_unread_outlined),
                    const SizedBox(width: 20),
                    Text(topic.topic,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _buildTopicItem(BuildContext context, SubscribeTopic topic) {
    PointerDownEvent? pointerEvent;
    return SizedBox(
      height: 70,
      child: InkWell(
        onTap: () {
          pushChatTopic(context, topic);
        },
        onLongPress: () {
          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
                pointerEvent!.position.dx,
                pointerEvent!.position.dy,
                pointerEvent!.position.dx,
                pointerEvent!.position.dy),
            items: <PopupMenuEntry>[
              const PopupMenuItem(
                value: 'Delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(
                      width: 5,
                    ),
                    Text("Delete")
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'Change',
                child: Row(
                  children: [
                    Icon(Icons.change_circle_outlined),
                    SizedBox(
                      width: 5,
                    ),
                    Text("Change")
                  ],
                ),
              ),
            ],
          );
        },
        child: Listener(
          onPointerDown: (PointerDownEvent event) {
            pointerEvent = event;
          },
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withOpacity(0.2),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_chat_unread_outlined),
                const SizedBox(width: 20),
                Text(topic.topic,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildAddTopicDialog(
      BuildContext context, ValueSetter<SubscribeTopic> callback) {
    final systemOverlayStyle = Color.alphaBlend(
        Colors.black54,
        ElevationOverlay.colorWithOverlay(Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceTint, 3));

    SubscribeTopic subscribeTopic = SubscribeTopic.empty();
    subscribeTopic.qos = 1;
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => SystemOverlayStyleWithBrightness(
          sized: false,
          systemNavigationBarColor: systemOverlayStyle,
          child: Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: [
                      const Icon(Icons.add),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Topic",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    cursorOpacityAnimates: true,
                    textInputAction: TextInputAction.newline,
                    autofocus: true,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "topic",
                    ),
                    onChanged: (String value) {
                      subscribeTopic.topic = value;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownMenu<int>(
                    initialSelection: 1,
                    requestFocusOnTap: true,
                    expandedInsets: const EdgeInsets.all(0),
                    label: const Text('Qos'),
                    onSelected: (int? value) {
                      subscribeTopic.qos = value ?? 1;
                    },
                    dropdownMenuEntries: qosList
                        .map<DropdownMenuEntry<int>>(((int, String) value) {
                      return DropdownMenuEntry<int>(
                          value: value.$1,
                          label: value.$2,
                          labelWidget: Row(
                            children: [Text(value.$2)],
                          ));
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Close',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ),
                      TextButton(
                        onPressed: () {
                          // 需要校验subscribeTopic
                          if (subscribeTopic.topic != "") {
                            callback(subscribeTopic);
                          }
                          Navigator.pop(context);
                        },
                        child: const Text('Confirm'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )),
    );
  }

  void pushChatTopic(BuildContext context, SubscribeTopic topic) {
    GoRouter.of(context).push("/chat_topic", extra: topic);
  }
}

const List<(int, String)> qosList = <(int, String)>[
  (0, "Qos 0"),
  (1, "Qos 1"),
  (2, "Qos 2"),
];

class BubblePainter extends CustomPainter {
  final double borderRadius;
  final double indicatorWidth;
  final double indicatorHeight;
  final Color bubbleColor;

  BubblePainter(
      {this.borderRadius = 10.0,
      this.indicatorWidth = 10.0,
      this.indicatorHeight = 5.0,
      this.bubbleColor = Colors.blue});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(borderRadius, 0)
      ..lineTo(size.width - borderRadius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, borderRadius)
      ..lineTo(size.width, size.height - borderRadius - indicatorHeight)
      ..quadraticBezierTo(size.width, size.height - indicatorHeight,
          size.width - borderRadius, size.height - indicatorHeight)
      ..lineTo(
          size.width / 2 + indicatorWidth / 2, size.height - indicatorHeight)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(
          size.width / 2 - indicatorWidth / 2, size.height - indicatorHeight)
      ..lineTo(borderRadius, size.height - indicatorHeight)
      ..quadraticBezierTo(0, size.height - indicatorHeight, 0,
          size.height - borderRadius - indicatorHeight)
      ..lineTo(0, borderRadius)
      ..quadraticBezierTo(0, 0, borderRadius, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
