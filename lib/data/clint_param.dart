import 'package:hive/hive.dart';

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
  String username = "";

  @HiveField(4)
  String password = "";
}
