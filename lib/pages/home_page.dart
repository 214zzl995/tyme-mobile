import 'package:flutter/material.dart';

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
