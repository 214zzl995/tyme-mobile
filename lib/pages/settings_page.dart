import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:tyme/data/clint_param.dart';

import '../data/clint_security_param.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          const SliverAppBar.large(
            leading: Icon(Icons.settings),
            title: Text('Setting'),
          ),
          ValueListenableBuilder(
              valueListenable:
                  Hive.box('tyme_config').listenable(keys: ["clint_param"]),
              builder: (context, tymeConfig, widget) {
                return SliverList.list(children: [
                  _buildSettingGroupHeader(context, "Clint"),
                  _buildSettingItem(
                      context,
                      "Broker",
                      tymeConfig.get("clint_param").broker,
                      Icons.cloud_outlined, () {
                    _buildEditDialog(
                        context,
                        "Broker",
                        tymeConfig.get("clint_param").broker,
                        Icons.cloud_outlined, (value) async {
                      final ClintParam clintParam =
                          tymeConfig.get("clint_param");

                      if (value != clintParam.broker) {
                        final editClintParam =
                            clintParam.copyWith(broker: value);
                        Hive.box('tyme_config')
                            .put("clint_param", editClintParam);
                      }
                    });
                  }),
                  _buildSettingItem(
                      context,
                      "Port",
                      tymeConfig.get("clint_param").port.toString(),
                      Icons.link_outlined, () {
                    _buildEditDialog(
                        context,
                        "Port",
                        tymeConfig.get("clint_param").port.toString(),
                        Icons.link_outlined, (value) async {
                      final ClintParam clintParam =
                          tymeConfig.get("clint_param");
                      if (value != clintParam.port) {
                        final editClintParam = clintParam.copyWith(port: value);

                        Hive.box('tyme_config')
                            .put("clint_param", editClintParam);
                      }
                    }, true, false, false);
                  }),
                  _buildSettingItem(
                      context,
                      "Clint ID",
                      tymeConfig.get("clint_param").clintId,
                      Icons.usb_outlined, () {
                    _buildEditDialog(
                        context,
                        "Clint ID",
                        tymeConfig.get("clint_param").clintId,
                        Icons.usb_outlined, (value) async {
                      final ClintParam clintParam =
                          tymeConfig.get("clint_param");

                      if (value != clintParam.clintId) {
                        final editClintParam =
                            clintParam.copyWith(clintId: value);

                        Hive.box('tyme_config')
                            .put("clint_param", editClintParam);
                      }
                    });
                  }),
                  _buildSettingItem(
                      context,
                      "Username",
                      tymeConfig.get("clint_param").username,
                      Icons.account_circle_outlined, () {
                    _buildEditDialog(
                        context,
                        "Username",
                        tymeConfig.get("clint_param").username,
                        Icons.account_circle_outlined, (value) async {
                      final ClintParam clintParam =
                          tymeConfig.get("clint_param");

                      if (value != clintParam.username) {
                        final editClintParam =
                            clintParam.copyWith(username: value);

                        Hive.box('tyme_config')
                            .put("clint_param", editClintParam);
                      }
                    }, false, false, true);
                  }),
                  _buildSettingItem(
                      context,
                      "Password",
                      tymeConfig.get("clint_param").password.toString().hide(),
                      Icons.password_outlined, () {
                    _buildEditDialog(
                        context,
                        "Password",
                        tymeConfig.get("clint_param").password,
                        Icons.password_outlined, (value) async {
                      final ClintParam clintParam =
                          tymeConfig.get("clint_param");

                      if (value != clintParam.password) {
                        final editClintParam =
                            clintParam.copyWith(password: value);

                        Hive.box('tyme_config')
                            .put("clint_param", editClintParam);

                      }
                    }, false, true, true);
                  }),
                  _buildSettingItem(
                      context,
                      "Certificate",
                      tymeConfig.get("clint_param").securityParam.filename,
                      Icons.security_outlined, () {
                    _filePicker(tymeConfig.get("clint_param")).then((_) {
                    });
                  }),
                ]);
              })
        ],
      ),
    );
  }

  Widget _buildSettingGroupHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.only(left: 20, top: 10, bottom: 5),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    String? subTitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.centerLeft,
        height: 80,
        padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  subTitle ?? "Not Set",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _buildEditDialog(BuildContext context, String title, String defaultValue,
      IconData icon, AsyncValueSetter confirmCallback,
      [bool number = false, bool password = false, bool canNull = false]) {
    String editText = "";

    showDialog<String>(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              TextField(
                controller: TextEditingController(text: defaultValue),
                obscureText: password,
                cursorOpacityAnimates: true,
                textInputAction: TextInputAction.newline,
                autofocus: true,
                maxLines: password ? 1 : null,
                keyboardType:
                    number ? TextInputType.number : TextInputType.multiline,
                inputFormatters: number
                    ? [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        LengthLimitingTextInputFormatter(5),
                      ]
                    : [],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: title,
                ),
                onChanged: (String value) {
                  editText = value;
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      dynamic confirmValue;
                      if (number) {
                        confirmValue =
                            int.parse(editText == "" ? "0" : editText);
                      } else {
                        confirmValue = editText;
                      }
                      if (canNull || (!canNull && editText != "")) {
                        confirmCallback(confirmValue);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Confirm'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Close'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  _filePicker(ClintParam clintParam) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['crt'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      String contents = await file.readAsString();
      String fileName = result.files.single.name;
      final securityParam =
          ClintSecurityParam(filename: fileName, fileContent: contents);

      final editClintParam = clintParam.copyWith(securityParam: securityParam);

      Hive.box('tyme_config').put("clint_param", editClintParam);
    } else {
      // User canceled the picker
    }
  }
}

extension HiddenString on String {
  String hide() {
    String hiddenString = '';
    for (int i = 0; i < length; i++) {
      hiddenString += '*';
    }
    return hiddenString;
  }
}
