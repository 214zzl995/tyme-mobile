import 'package:flutter/cupertino.dart';
import 'package:provider/single_child_widget.dart';

class DetectLifecycle extends SingleChildStatefulWidget {
  const DetectLifecycle({
    Key? key,
    required this.build,
    Widget? child,
  }) : super(key: key, child: child);

  final ValueWidgetBuilder<AppLifecycleState> build;

  @override
  State<StatefulWidget> createState() => _DetectLifecycleState();
}

class _DetectLifecycleState extends SingleChildState<DetectLifecycle>
    with WidgetsBindingObserver {
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_lifecycleState != state) {
      setState(() {
        _lifecycleState = state;
      });
    }
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) =>
      widget.build(context, _lifecycleState, child);
}
