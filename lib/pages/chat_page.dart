import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/clint.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          const SliverAppBar.large(
            leading: Icon(Icons.chat),
            title: Text('Chat'),
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
          Selector<Clint, List<String>>(
            builder: (BuildContext context, List<String> subscribeTopics,
                Widget? child) {
              return SliverList(
                delegate: SliverChildListDelegate(
                  <Widget>[
                    ...subscribeTopics
                        .map((topic) => _buildTopicItem(context, topic))
                  ],
                ),
              );
            },
            selector: (context, clint) => clint.clintParam.subscribeTopic,
          ),
        ],
      ),
    );
  }

  Widget _buildTopicItem(BuildContext context, String topic) {
    GlobalKey key = GlobalKey();
    return SizedBox(
      key: key,
      height: 60,
      child: InkWell(
        onTap: () {},
        onLongPress: () {
          RenderBox box = key.currentContext?.findRenderObject() as RenderBox;
          Offset position = box.localToGlobal(Offset.zero);
          Size size = box.size;
          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
              position.dx + size.width,
              position.dy + size.height / 2,
              position.dx + size.width,
              position.dy + size.height / 2,
            ),
            items: <PopupMenuEntry>[
              const PopupMenuItem(
                value: 'option1',
                child: Text('Option 1'),
              ),
              const PopupMenuItem(
                value: 'option2',
                child: Text('Option 2'),
              ),
            ],
          );
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
              Text(topic, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
