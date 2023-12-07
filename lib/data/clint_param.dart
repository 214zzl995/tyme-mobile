import 'package:hive/hive.dart';

import 'clint_security_param.dart';

part 'clint_param.g.dart';

@HiveType(typeId: 1)
class ClintParam {
  @HiveField(0)
  String broker = "";

  @HiveField(1)
  int port = -1;

  @HiveField(2)
  String clintId = "";

  @HiveField(3)
  String? username;

  @HiveField(4)
  String? password;

  @HiveField(5)
  ClintSecurityParam? securityParam;

  bool get isComplete =>
      broker != "" &&
      port != -1 &&
      clintId != "" &&
      ((username != null) == (password != null));

  copyWith({
    String? broker,
    int? port,
    String? clintId,
    String? username,
    String? password,
    ClintSecurityParam? securityParam,
  }) {
    return ClintParam(
      broker ?? this.broker,
      port ?? this.port,
      clintId ?? this.clintId,
      username ?? this.username,
      password ?? this.password,
      securityParam ?? this.securityParam,
    );
  }

  ClintParam([
    this.broker = "",
    this.port = -1,
    this.clintId = "",
    this.username,
    this.password,
    this.securityParam,
  ]);
}
