import 'package:hive/hive.dart';

part 'client_security_param.g.dart';

@HiveType(typeId: 2)
class ClientSecurityParam {
  @HiveField(0)
  final String filename;

  @HiveField(1)
  final String fileContent;

  const ClientSecurityParam({
    this.filename = "",
    this.fileContent = "",
  });
}
