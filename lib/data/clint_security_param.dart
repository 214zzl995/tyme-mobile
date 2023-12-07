import 'package:hive/hive.dart';

part 'clint_security_param.g.dart';

@HiveType(typeId: 2)
class ClintSecurityParam {
  @HiveField(0)
  final String filename;

  @HiveField(1)
  final String fileContent;

  const ClintSecurityParam({
    this.filename = "",
    this.fileContent = "",
  });
}
