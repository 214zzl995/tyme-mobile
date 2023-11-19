import 'dart:core';

import 'package:flutter/cupertino.dart';

class Server {
  Server(this.name, this.ip, this.status, this.cpuUtilization,
      this.memoryUtilization);

  String name;
  String ip;
  ServerStatus status;
  double cpuUtilization;
  double memoryUtilization;
  int time = DateTime.now().millisecondsSinceEpoch;

  update({
    String? name,
    String? ip,
    ServerStatus? status,
    double? cpuUtilization,
    double? memoryUtilization,
  }) {
    this.name = name ?? this.name;
    this.ip = ip ?? this.ip;
    this.status = status ?? this.status;
    this.cpuUtilization = cpuUtilization ?? this.cpuUtilization;
    this.memoryUtilization = memoryUtilization ?? this.memoryUtilization;
    time = DateTime.now().millisecondsSinceEpoch;
  }

  copyWith({
    String? name,
    String? ip,
    ServerStatus? status,
    double? cpuUtilization,
    double? memoryUtilization,
  }) {
    return Server(
      name ?? this.name,
      ip ?? this.ip,
      status ?? this.status,
      cpuUtilization ?? this.cpuUtilization,
      memoryUtilization ?? this.memoryUtilization,
    );
  }


  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode + time;

  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
}

enum ServerStatus {
  stop,
  running,
  unknown,
}

class HomeData with ChangeNotifier {
  final List<Server> _servers = [
    Server("server1", "127.0.0.1", ServerStatus.unknown, 0, 0),
  ];

  List<Server> get servers => _servers;
}
