import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tyme/routers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("MyApp build");
    return PageStorageBucketProvider(
      bucket: PageStorageBucket(),
      child: MaterialApp.router(
        supportedLocales: const [Locale("zh", "CN"), Locale("en", "US")],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: TymeRouteConfiguration.routers,
      ),
    );
  }
}

class PageStorageBucketProvider extends InheritedWidget {
  final PageStorageBucket bucket;

  const PageStorageBucketProvider({
    Key? key,
    required this.bucket,
    required Widget child,
  }) : super(key: key, child: child);

  static PageStorageBucketProvider? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PageStorageBucketProvider>();
  }

  @override
  bool updateShouldNotify(PageStorageBucketProvider oldWidget) {
    return bucket != oldWidget.bucket;
  }
}
