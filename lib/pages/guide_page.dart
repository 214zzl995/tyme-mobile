import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:tyme/data/clint_security_param.dart';

import '../components/slide_fade_transition.dart';
import '../data/clint_param.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  GuidePageState createState() => GuidePageState();
}

class GuidePageState extends State<GuidePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Container(
        color: Theme.of(context).colorScheme.background,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 250,
              padding: const EdgeInsets.only(top: 75, left: 20, right: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomLeft,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.background
                  ],
                ),
              ),
              child: Text(
                'Tyme',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            Expanded(
                child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                GuideChatDemo(
                  tabController: _tabController,
                ),
                const GuideSetting()
              ],
            ))
          ],
        ),
      ),
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class GuideChatDemo extends StatelessWidget {
  const GuideChatDemo({Key? key, required this.tabController})
      : super(key: key);

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildShowChatCard(context, false, "# **Hello**"),
        _buildShowChatCard(context, true, "😊"),
        _buildShowChatCard(context, false, '''
## System Information:
- CPU Usage: 23%
- Total Memory: 8.00 GB
- Used Memory: 3.25 GB
- Memory Usage: 40%
            '''),
        _buildGetStartButton(context)
      ],
    );
  }

  Widget _buildGetStartButton(BuildContext context) {
    return Expanded(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: Align(
              alignment: Alignment.bottomRight,
              child: SlideFadeTransition(
                  direction: Direction.horizontal,
                  curve: Curves.easeIn,
                  offset: 5,
                  animationDuration: const Duration(milliseconds: 1300),
                  child: SizedBox(
                    width: 200,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        tabController.index = 1;
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor:
                            Theme.of(context).colorScheme.background,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      icon: const Icon(Icons.settings),
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(
                            width: 50,
                          ),
                          Text("Get Start")
                        ],
                      ),
                    ),
                  )))),
    );
  }

  Widget _buildShowChatCard(BuildContext context, bool mine, String data) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: SlideFadeTransition(
        direction: Direction.vertical,
        curve: Curves.easeIn,
        offset: 2,
        animationDuration: const Duration(milliseconds: 1000),
        child: Container(
          decoration: BoxDecoration(
              color: mine
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant)),
          width: 270,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 10, left: 8, right: 8),
          child: MarkdownBody(data: data),
        ),
      ),
    );
  }
}

class GuideSetting extends StatelessWidget {
  const GuideSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final clintParamListenable = ValueNotifier(ClintParam());

    return ValueListenableBuilder(
        valueListenable: clintParamListenable,
        builder: (context, clintParam, widget) {
          return Stack(
            children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
                  child: Column(
                    children: [
                      _buildSubmitButton(context, clintParam),
                      Expanded(
                          child: ListView(
                        padding: const EdgeInsets.only(top: 5),
                        children: [
                          _buildSettingInput(
                              context,
                              "Broker",
                              Icons.cloud_outlined,
                              false,
                              false,
                              false, (value) {
                            clintParamListenable.value =
                                clintParam.copyWith(broker: value);
                          }),
                          _buildSettingInput(context, "Port",
                              Icons.link_outlined, true, false, false, (value) {
                            clintParamListenable.value = clintParam.copyWith(
                                port: int.parse(value == "" ? "0" : value));
                          }),
                          _buildSettingInput(context, "ClintId",
                              Icons.usb_outlined, false, false, false, (value) {
                            clintParamListenable.value =
                                clintParam.copyWith(clintId: value);
                          }),
                          _buildSettingInput(context, "Username",
                              Icons.man_outlined, false, false, true, (value) {
                            clintParamListenable.value =
                                clintParam.copyWith(username: value);
                          }),
                          _buildSettingInput(context, "Password",
                              Icons.password, false, true, true, (value) {
                            clintParamListenable.value =
                                clintParam.copyWith(password: value);
                          }),
                          _buildCrtFilePicker(context, clintParam, (value) {
                            clintParamListenable.value =
                                clintParam.copyWith(securityParam: value);
                          }),
                        ],
                      ))
                    ],
                  )),
            ],
          );
        });
  }

  Widget _buildSubmitButton(BuildContext context, ClintParam clintParam) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 50,
        width: 150,
        child: ElevatedButton.icon(
          onPressed: clintParam.isComplete
              ? () {
                  Hive.box('tyme_config')
                      .put("clint_param", clintParam)
                      .then((_) {
                    GoRouter.of(context).goNamed("Home");
                  });
                }
              : null,
          icon: clintParam.isComplete
              ? const Icon(Icons.check_circle_outlined)
              : const Icon(Icons.error_outline_outlined),
          label: const Text('Submit'),
        ),
      ),
    );
  }

  Widget _buildSettingInput(
    BuildContext context,
    String label,
    IconData icon,
    bool number,
    bool password,
    bool canNull,
    ValueChanged<String> onChanged,
  ) {
    return Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 25,
                ),
                SizedBox(
                  width: 25,
                  child: canNull
                      ? null
                      : Text(
                          "*",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                ),
                Expanded(
                  child: SizedBox(
                      height: 60,
                      child: TextField(
                        obscureText: password,
                        cursorOpacityAnimates: true,
                        keyboardType:
                            number ? TextInputType.number : TextInputType.text,
                        inputFormatters: number
                            ? [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9]')),
                                LengthLimitingTextInputFormatter(5),
                              ]
                            : [],
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: label,
                        ),
                        onChanged: onChanged,
                      )),
                )
              ],
            )
          ],
        ));
  }

  Widget _buildCrtFilePicker(
    BuildContext context,
    ClintParam clintParam,
    ValueChanged<ClintSecurityParam> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.security_outlined,
                size: 25,
              ),
              const SizedBox(
                width: 25,
              ),
              Expanded(
                child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['crt'],
                        );
                        if (result != null) {
                          File file = File(result.files.single.path!);
                          String contents = await file.readAsString();
                          String fileName = result.files.single.name;
                          final securityParam = ClintSecurityParam(
                              filename: fileName, fileContent: contents);
                          onChanged(securityParam);
                        } else {
                          // User canceled the picker
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(12),
                        elevation: 0,
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1),
                      ),
                      child: Text(
                          clintParam.securityParam == null
                              ? 'Select Crt File'
                              : clintParam.securityParam!.filename,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).colorScheme.primary,
                          )),
                    )),
              )
            ],
          )
        ],
      ),
    );
  }
}
