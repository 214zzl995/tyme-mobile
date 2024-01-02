import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:tyme/data/client_param.dart';

import '../components/system_overlay_style_with_brightness.dart';
import '../data/client_security_param.dart';
import '../provider/client.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool> refresh = ValueNotifier(false);
    ClientParam beginClientParam = Hive.box('tyme_config').get("client_param");
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          const SliverAppBar.large(
            leading: Icon(Icons.settings),
            title: Text('Setting'),
          ),
          ValueListenableBuilder(
              valueListenable:
                  Hive.box('tyme_config').listenable(keys: ["client_param"]),
              builder: (context, tymeConfig, widget) {
                final clientParam = tymeConfig.get("client_param") as ClientParam;
                return SliverList.list(children: [
                  _buildSettingGroupHeader(context, "Client"),
                  _buildSettingItem(context, "Broker", clientParam.broker,
                      Icons.cloud_outlined, () {
                    _buildEditDialog(context, "Broker", clientParam.broker,
                        Icons.cloud_outlined, (value) async {
                      if (value != clientParam.broker) {
                        final editClientParam =
                            clientParam.copyWith(broker: value);
                        Hive.box('tyme_config')
                            .put("client_param", editClientParam);

                        refresh.value = !editClientParam.equals(beginClientParam);
                      }
                    });
                  }),
                  _buildSettingItem(context, "Port", clientParam.port.toString(),
                      Icons.link_outlined, () {
                    _buildEditDialog(
                        context,
                        "Port",
                        clientParam.port.toString(),
                        Icons.link_outlined, (value) async {
                      if (value != clientParam.port) {
                        final editClientParam = clientParam.copyWith(port: value);

                        Hive.box('tyme_config')
                            .put("client_param", editClientParam);

                        refresh.value = !editClientParam.equals(beginClientParam);
                      }
                    }, number: true);
                  }),
                  _buildSettingItem(context, "Client ID", clientParam.clientId,
                      Icons.usb_outlined, () {
                    _buildEditDialog(context, "Client ID", clientParam.clientId,
                        Icons.usb_outlined, (value) async {
                      if (value != clientParam.clientId) {
                        final editClientParam =
                            clientParam.copyWith(clientId: value);

                        Hive.box('tyme_config')
                            .put("client_param", editClientParam);

                        refresh.value = !editClientParam.equals(beginClientParam);
                      }
                    });
                  }),
                  _buildSettingItem(context, "Username", clientParam.username,
                      Icons.account_circle_outlined, () {
                    _buildEditDialog(context, "Username", clientParam.username,
                        Icons.account_circle_outlined, (value) async {
                      if (value != clientParam.username) {
                        final editClientParam =
                            clientParam.copyWith(username: value);

                        Hive.box('tyme_config')
                            .put("client_param", editClientParam);

                        refresh.value = !editClientParam.equals(beginClientParam);
                      }
                    }, canNull: true);
                  }),
                  _buildSettingItem(context, "Password",
                      clientParam.password?.hide(), Icons.password_outlined, () {
                    _buildEditDialog(context, "Password", clientParam.password,
                        Icons.password_outlined, (value) async {
                      if (value != clientParam.password) {
                        final editClientParam =
                            clientParam.copyWith(password: value);

                        Hive.box('tyme_config')
                            .put("client_param", editClientParam);

                        refresh.value = !editClientParam.equals(beginClientParam);
                      }
                    }, password: true, canNull: true);
                  }),
                  _buildSettingItem(
                      context,
                      "Certificate",
                      clientParam.securityParam?.filename,
                      Icons.security_outlined, () {
                    _filePicker(tymeConfig.get("client_param"))
                        .then((editClientParam) {
                      refresh.value = !editClientParam.equals(beginClientParam);
                    });
                  }),
                ]);
              })
        ],
      ),
      floatingActionButton: ValueListenableBuilder(
        valueListenable: refresh,
        builder: (context, refreshEnable, child) {
          if (!refreshEnable) {
            return Container();
          }
          return child!;
        },
        child: FloatingActionButton(
          onPressed: () {
            final clientParam =
                Hive.box('tyme_config').get("client_param") as ClientParam;
            beginClientParam = clientParam;
            context.read<Client>().restart(clientParam);
            refresh.value = false;
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.refresh),
        ),
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
                if (subTitle != null)
                  Text(
                    subTitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _buildEditDialog(BuildContext context, String title, String? defaultValue,
      IconData icon, AsyncValueSetter confirmCallback,
      {bool number = false,
      bool password = false,
      bool canNull = false}) async {
    String editText = "";
    final systemOverlayStyle = Color.alphaBlend(
        Colors.black54,
        ElevationOverlay.colorWithOverlay(Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceTint, 3));

    await showDialog<String>(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: SystemOverlayStyleWithBrightness(
          sized: false,
          systemNavigationBarColor: systemOverlayStyle,
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
                        Navigator.pop(context);
                      },
                      child: Text('Close',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ),
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
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<ClientParam> _filePicker(ClientParam clientParam) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['crt'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      String contents = await file.readAsString();
      String fileName = result.files.single.name;
      final securityParam =
          ClientSecurityParam(filename: fileName, fileContent: contents);

      final editClientParam = clientParam.copyWith(securityParam: securityParam);

      Hive.box('tyme_config').put("client_param", editClientParam);

      return editClientParam;
    }
    return clientParam;
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
