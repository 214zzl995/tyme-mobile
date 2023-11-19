import 'package:flutter/material.dart';

import '../main.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PageStorage(
      bucket: PageStorageBucketProvider.of(context)!.bucket,
      child: CustomScrollView(
        key: const PageStorageKey("home_page_scroll_view"),
        controller: ScrollController(),
        slivers: <Widget>[
          const SliverAppBar.large(
            leading: Icon(Icons.home),
            title: Text('Home Page'),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              <Widget>[
                ...List.generate(
                    100,
                    (index) => ListTile(
                          title: Text('Item $index'),
                        ))

                // Add more items here
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildServerCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {

        },
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


