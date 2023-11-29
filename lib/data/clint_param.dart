import 'package:hive/hive.dart';

part 'clint_param.g.dart';

@HiveType(typeId: 1)
class ClintParam {
  @HiveField(0)
  late String broker;

  @HiveField(1)
  late int port;

  @HiveField(2)
  late String clintId;

  @HiveField(3)
  late String username;

  @HiveField(4)
  late String password;
}
