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

  late int _readIndex;
  late final ValueNotifier<bool> _noMore =
      ValueNotifier(_pageInitialData.isEmpty || _pageInitialData.last.$1 == 0);

  final ValueNotifier<int> _unreadCount = ValueNotifier(0);

  late int _messageMaxIndex;

  late int moreMessageNumber;

  late int skipCount;
  bool _remove = false;

  final Stream<List<(int, ChatMessage)>> _mqttMessageStream;

  late List<(int, ChatMessage)> _pageInitialData =
      _initialData.reversed.toList();

  late final _oldMaxIndex =
      _pageInitialData.isEmpty ? -1 : _pageInitialData.first.$1;

  late final ValueNotifier<bool> _emptyMessage =
      ValueNotifier(_pageInitialData.isEmpty);

  late final StreamController<List<(int, ChatMessage)>>
      _mqttMessageStreamController = BehaviorSubject();

  late final StreamController<List<(int, ChatMessage)>>
      _pageMessageStreamController = BehaviorSubject.seeded(_pageInitialData);

  late Stream<List<(int, ChatMessage)>> mqttMessageStream =
      _mqttMessageStreamController.stream.scan((accumulated, value, index) {
    if (value.isEmpty) {
      return [];
    }

    final accumulatedMaxIndex =
        accumulated.isEmpty ? _oldMaxIndex : accumulated.last.$1;

    final newMessages = value.mapIndexed(
        (index, message) => (index + accumulatedMaxIndex + 1, message.$2));

    _unreadCount.value = newMessages.last.$1 - _readIndex;
    _messageMaxIndex = newMessages.last.$1;

    return [...accumulated, ...newMessages];
  }, []);

  late Stream<List<(int, ChatMessage)>> pageMessageStream =
      _pageMessageStreamController.stream.scan((accumulated, value, index) {
    if (_remove) {
      _remove = false;
      return [];
    }
    return [...accumulated, ...value];
  }, []);

  late StreamSubscription _emptyMqttMessageStreamSubscription;

  TopicChatData(this.topic, this._mqttMessageStream,
      {this.preloadCount = 20, this.moreMessageNumber = 30}) {
    _readIndex = Hive.box(readBox).get(key, defaultValue: -1);
    final length = Hive.box<ChatMessage>(key).length;

    final normalBegin = length > preloadCount ? length - preloadCount : 0;

    skipCount = _readIndex - normalBegin > -10
        ? normalBegin
        : _readIndex > 10
            ? _readIndex - 10
            : 0;

    _messageMaxIndex = length - 1;

    if (pageInitialData.isEmpty) {
      _addEmptyMqttMessageStreamSubscription();
    }

    _mqttMessageStream
        .where((event) => event.isNotEmpty)
        .listen(_mqttMessageStreamController.add);
  }

  void changeReadIndex(int index) {
    if (index > _readIndex) {
      _readIndex = index;
      _unreadCount.value = _messageMaxIndex - _readIndex;
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

    if (moreMessages.first.$1 == 0) {
      _noMore.value = true;
    }

    skipCount = skipCount - moreMessages.length;

    return moreMessages;
  }

  void loadMore() {
    final moreMessages = this.moreMessages.reversed.toList();
    _pageMessageStreamController.add(moreMessages);
  }

  void removeAll() async {
    if (!emptyMessage.value) {
      emptyMessage.value = true;
    }
    await Hive.box<ChatMessage>(key).clear();
    await Hive.box(readBox).put(key, -1);
    skipCount = 0;
    _readIndex = 0;
    _remove = true;
    _noMore.value = true;
    _unreadCount.value = 0;
    _messageMaxIndex = 0;
    _pageInitialData = [];
    _pageMessageStreamController.add([]);
    _mqttMessageStreamController.add([]);
    _addEmptyMqttMessageStreamSubscription();
  }

  ValueNotifier<bool> get emptyMessage => _emptyMessage;

  ValueNotifier<int> get unreadCount => _unreadCount;

  List<(int, ChatMessage)> get pageInitialData => _pageInitialData;

  int get readIndex => _readIndex;

  ValueNotifier<bool> get noMore => _noMore;
}
