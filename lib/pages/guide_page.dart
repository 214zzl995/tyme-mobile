import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../components/slide_fade_transition.dart';

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
      body: Container(
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
    );
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
        _buildShowChatCard(context, true, "### Fuck You 😊"),
        _buildShowChatCard(context, false,
            '''
            ## **系统信息**：
            - CPU使用率: 23%
            - 总内存: 8.00 GB
            - 已使用内存: 3.25 GB
            - 内存使用率: 40%
            '''
        ),
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
    return Container();
  }
}
