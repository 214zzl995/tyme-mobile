import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:rxdart/rxdart.dart';

import 'chat_message.dart';
import 'client_param.dart';

class TopicChatData {
  static String readBox = "tyme_chat_read_index";

  late String key = topic.hiveKey;

  final SubscribeTopic topic;
  int preloadCount;

  late int readIndex;

  late int moreMessageNumber;

  late int skipCount;
  bool _remove = false;

  final StreamController<List<(int, ChatMessage)>>
      _mqttMessageStreamController =
      StreamController<List<(int, ChatMessage)>>();

  final Stream<List<(int, ChatMessage)>> _mqttMessageStream;

  final StreamController<List<(int, ChatMessage)>>
      _pageMessageStreamController =
      StreamController<List<(int, ChatMessage)>>();

  late List<(int, ChatMessage)> _pageInitialData =
      _initialData.reversed.toList();

  late final _oldMaxIndex =
      _pageInitialData.isEmpty ? -1 : _pageInitialData.first.$1;

  late final ValueNotifier _emptyMessage =
      ValueNotifier(_pageInitialData.isEmpty);

  ValueNotifier get emptyMessage => _emptyMessage;

  List<(int, ChatMessage)> get pageInitialData => _pageInitialData;

  late StreamSubscription _emptyMqttMessageStreamSubscription;

  late Stream<List<(int, ChatMessage)>> mqttMessageStream = _mqttMessageStream
      .mergeWith([_mqttMessageStreamController.stream]).scan(
          (accumulated, value, index) {
    if (value.isEmpty) {
      return [];
    }
    if (emptyMessage.value) {
      emptyMessage.value = false;
    }

    final accumulatedMaxIndex =
        accumulated.isEmpty ? _oldMaxIndex : accumulated.last.$1;

    final newMessages = value.mapIndexed(
        (index, message) => (index + accumulatedMaxIndex + 1, message.$2));

    return [...accumulated, ...newMessages];
  }, []);

  late Stream<List<(int, ChatMessage)>> pageMessageStream =
      _pageMessageStreamController.stream.startWith(_pageInitialData).scan(
          (accumulated, value, index) {
    if (accumulated.isNotEmpty &&
        accumulated.last.$1 == 0 &&
        value.isEmpty &&
        _remove) {
      _remove = false;
      return [];
    }
    return [...accumulated, ...value];
  }, []);

  TopicChatData(this.topic, this._mqttMessageStream,
      {this.preloadCount = 20, this.moreMessageNumber = 30}) {
    readIndex = Hive.box(readBox).get(key, defaultValue: -1);
    final length = Hive.box<ChatMessage>(key).length;

    final normalBegin = length > preloadCount ? length - preloadCount : 0;

    skipCount = readIndex - normalBegin > -10
        ? normalBegin
        : readIndex > 10
            ? readIndex - 10
            : 0;

    if (pageInitialData.isEmpty) {
      _addEmptyMqttMessageStreamSubscription();
    }

    Hive.box(readBox).listenable(keys: [key]).addListener(() {
      final readIndex = Hive.box(readBox).get(key);
      debugPrint("read_index changed,index:$readIndex");
      this.readIndex = readIndex;
    });
  }

  void changeReadIndex(int index) {
    if (index > readIndex) {
      readIndex = index;
      Hive.box(readBox).put(key, index);
    }
  }

  void _addEmptyMqttMessageStreamSubscription() {
    _emptyMqttMessageStreamSubscription = _mqttMessageStream.listen((event) {
      _emptyMessage.value = false;
      _emptyMqttMessageStreamSubscription.cancel();
    });
  }

  List<(int, ChatMessage)> get _initialData {
    final box = Hive.box<ChatMessage>(key);
    final length = box.length;

    return box
        .valuesBetween(startKey: skipCount, endKey: length)
        .mapIndexed((index, msg) => (index + skipCount, msg))
        .toList();
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

  void loadMore() {
    final moreMessages = this.moreMessages.reversed.toList();
    _pageMessageStreamController.add(moreMessages);
  }

  void removeAll() async {
    await Hive.box<ChatMessage>(key).clear();
    await Hive.box(readBox).put(key, -1);
    skipCount = 0;
    readIndex = 0;
    _remove = true;
    _pageMessageStreamController.add([]);
    _mqttMessageStreamController.add([]);
    _pageInitialData = [];
    _addEmptyMqttMessageStreamSubscription();
    if (!emptyMessage.value) {
      emptyMessage.value = true;
    }
  }
}
