import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

import '../data/clint_param.dart';

class TopicReadIndex {

  static String readBox = "tyme_chat_read_index";
  TopicReadIndex(this.topic) {

    readIndex = Hive.box(readBox).get(key, defaultValue: 0);
    Hive.box(readBox).listenable(keys: [key]).addListener(() {
      debugPrint("read_index changed");
      readIndex = Hive.box(readBox).get(key);
    });
  }

  late String key = topic.getHiveKey();

  final SubscribeTopic topic;

  int readIndex = 0;

  void changeReadIndex(int index) {
    if (index > readIndex) {
      Hive.box(readBox).put(key, index);
    }

  }
}
