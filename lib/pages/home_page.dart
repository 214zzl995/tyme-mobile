import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../provider/clint.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        key: const PageStorageKey("home_page_scroll_view"),
        controller: ScrollController(),
        slivers: <Widget>[
          const SliverAppBar.large(
            leading: Icon(Icons.home),
            title: Text('Home'),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              <Widget>[
                ElevatedButton(
                  onPressed: () {
                    // GoRouter.of(context).goNamed("Guide");
                    final param = context.read<Clint>().clintParam;
                    final param1 = param.copyWith(subscribeTopic: ["chat/#","chat1/#","chat2/#","chat3/#"]);

                    Hive.box("tyme_config").put("clint_param", param1);
                  },
                  child: const Text('Demo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {},
        child: const Card(
          child: ListTile(
            leading: Icon(Icons.home),
            title: Text('Home Page'),
          ),
        ),
      ),
    );
  }
}
