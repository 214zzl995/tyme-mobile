import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/adapters.dart';

import 'chat_message.dart';
import 'clint_param.dart';

class TopicReadIndex {
  static String readBox = "tyme_chat_read_index";

  late String key = topic.hiveKey;

  final SubscribeTopic topic;
  int preloadCount;

  late int readIndex;

  late int moreMessageNumber;

  late int skipCount;

  TopicReadIndex(this.topic,
      {this.preloadCount = 20, this.moreMessageNumber = 30}) {
    readIndex = Hive.box(readBox).get(key, defaultValue: 0);
    final length = Hive.box<ChatMessage>(key).length;

    final normalBegin = length > preloadCount ? length - preloadCount : 0;

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
    if (index > readIndex) {
      Hive.box(readBox).put(key, index);
    }
  }

  List<(int, ChatMessage)> get topicInitialData {
    final box = Hive.box<ChatMessage>(key);
    final length = box.length;

    List<(int, ChatMessage)> startMessages = box
        .valuesBetween(startKey: skipCount, endKey: length)
        .mapIndexed((index, msg) => (index + skipCount, msg))
        .toList();

    final reversedStartMessages = startMessages.reversed.toList();

    return reversedStartMessages;
  }

  List<(int, ChatMessage)> get moreData {
    final box = Hive.box<ChatMessage>(key);
    int startKey = skipCount - moreMessageNumber;
    startKey = startKey < 0 ? 0 : startKey;
    final endKey = box.length;

    List<(int, ChatMessage)> startMessages = box
        .valuesBetween(startKey: startKey, endKey: endKey)
        .mapIndexed((index, msg) => (index + startKey, msg))
        .toList();

    skipCount = skipCount - startMessages.length;

    final reversedStartMessages = startMessages.reversed.toList();
    return reversedStartMessages;
  }


  ///获取手动导入的 Stream 和 mqtt的Stream
}
