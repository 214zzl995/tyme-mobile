import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/single_child_widget.dart';

class DetectLifecycleScrollTo extends SingleChildStatefulWidget {
  const DetectLifecycleScrollTo({
    Key? key,
    required this.scroll,
    required Widget child,
  }) : super(key: key, child: child);

  final VoidCallback scroll;

  @override
  State<StatefulWidget> createState() => _DetectLifecycleScrollToState();
}

class _DetectLifecycleScrollToState extends SingleChildState<DetectLifecycleScrollTo>
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
      widget.scroll();
    }
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) => child!;
}
