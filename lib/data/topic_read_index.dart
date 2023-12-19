import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:rxdart/rxdart.dart';

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

  int test = 0;

  final Stream<List<(int, ChatMessage)>> _mqttMessageStream;

  final StreamController<List<(int, ChatMessage)>>
      _pageMessageStreamController =
      StreamController<List<(int, ChatMessage)>>();

  late final Stream<List<(int, ChatMessage)>> messageStream = _mqttMessageStream
      .mergeWith([
    _pageMessageStreamController.stream.startWith(initialData)
  ]).scan<List<(int, ChatMessage)>>(
    (accumulatedMessages, newMessages, _) {
      if (newMessages.isEmpty && accumulatedMessages.isEmpty) {
        return [];
      }
      if (newMessages.isEmpty) {
        return accumulatedMessages;
      }
      if (newMessages.first.$1 == -1) {
        final maxIndex =
            accumulatedMessages.isEmpty ? -1 : accumulatedMessages.last.$1;

        final newMessagesWithIndex = newMessages
            .mapIndexed((index, msg) => (index + maxIndex + 1, msg.$2))
            .toList();
        test = test + 1;
        return [...accumulatedMessages, ...newMessagesWithIndex];
      } else {
        return [...newMessages, ...accumulatedMessages];
      }
    },
    [],
  );

  late final Stream<List<(int, ChatMessage)>> messageStreamR =
      _mqttMessageStream.mergeWith([
    _pageMessageStreamController.stream.startWith(initialDataR)
  ]).scan<List<(int, ChatMessage)>>(
    (accumulatedMessages, newMessages, _) {
      if (newMessages.isEmpty && accumulatedMessages.isEmpty) {
        return [];
      }
      if (newMessages.isEmpty) {
        return accumulatedMessages;
      }
      if (newMessages.first.$1 == -1) {
        final maxIndex =
            accumulatedMessages.isEmpty ? -1 : accumulatedMessages.first.$1;

        final newMessagesWithIndex = newMessages
            .mapIndexed((index, msg) => (index + maxIndex + 1, msg.$2))
            .toList();

        return [...newMessagesWithIndex, ...accumulatedMessages];
      } else {
        return [...accumulatedMessages, ...newMessages];
      }
    },
    [],
  );

  TopicReadIndex(this.topic, this._mqttMessageStream,
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

  List<(int, ChatMessage)> get initialData {
    final box = Hive.box<ChatMessage>(key);
    final length = box.length;

    return box
        .valuesBetween(startKey: skipCount, endKey: length)
        .mapIndexed((index, msg) => (index + skipCount, msg))
        .toList();
  }

  List<(int, ChatMessage)> get initialDataR {
    return initialData.reversed.toList();
  }

  List<(int, ChatMessage)> get moreMessages {
    final box = Hive.box<ChatMessage>(key);
    int startKey =
        skipCount - moreMessageNumber < 0 ? 0 : skipCount - moreMessageNumber;
    int endKey = skipCount - 1 < 0 ? 0 : skipCount - 1;

    if (startKey == 0 && endKey == 0) {
      return [];
    }

    List<(int, ChatMessage)> moreMessages = box
        .valuesBetween(startKey: startKey, endKey: endKey)
        .mapIndexed((index, msg) => (index + startKey, msg))
        .toList();

    skipCount = skipCount - moreMessages.length;

    return moreMessages;
  }

  List<(int, ChatMessage)> get moreMessagesR {
    return moreMessages.reversed.toList();
  }

  int loadMore() {
    final moreMessages = this.moreMessages;
    _pageMessageStreamController.add(moreMessages);
    return moreMessages.length;
  }

  void loadMoreR() {
    _pageMessageStreamController.add(moreMessagesR);
  }
}
