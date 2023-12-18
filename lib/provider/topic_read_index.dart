import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/adapters.dart';

import '../data/chat_message.dart';
import '../data/clint_param.dart';

class TopicReadIndex {
  static String readBox = "tyme_chat_read_index";

  late String key = topic.getHiveKey();

  final SubscribeTopic topic;

  int readIndex = 0;

  BuildContext? chatListCtx;

  GlobalKey appBarKey = GlobalKey();

  int skipCount = 0;

  int get readInitIndex => readIndex - skipCount;

  TopicReadIndex(this.topic) {
    readIndex = Hive.box(readBox).get(key, defaultValue: 0);
    final length = Hive.box<ChatMessage>(key).length;

    final normalBegin = length > 30 ? length - 30 : 0;

    skipCount = readIndex - normalBegin > -10
        ? normalBegin
        : readIndex > 10
        ? readIndex - 10
        : 0;
    Hive.box(readBox).listenable(keys: [key]).addListener(() {
      debugPrint("read_index changed");
      readIndex = Hive.box(readBox).get(key);
    });
  }

  void changeReadIndex(int index) {
    debugPrint("changeReadIndex,now index is $index,readIndex is $readIndex");
    if (index > readIndex) {
      Hive.box(readBox).put(key, index);
    }
  }

  List<(int, ChatMessage)> get topicInitialData {
    final box = Hive.box<ChatMessage>(key);
    final length = box.length;

    List<(int, ChatMessage)>? startMessages = box
        .valuesBetween(startKey: skipCount, endKey: length)
        .mapIndexed((index, msg) => (index + skipCount, msg))
        .toList();
    return startMessages;
  }
}
