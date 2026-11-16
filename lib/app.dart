import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'core/app_binding.dart';
import 'core/navigation.dart';
import 'core/scroll_behavior.dart';
import 'core/theme.dart';
import 'router.dart';

class NewsAiApp extends StatefulWidget {
  const NewsAiApp({super.key});

  @override
  State<NewsAiApp> createState() => _NewsAiAppState();
}

class _NewsAiAppState extends State<NewsAiApp> {
  // Created once so rebuilds never reset navigation.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter();
    AppNav.router = _router;
    // Deep links that arrive while the app is already running (warm app).
    // Cold-start links are matched by the initial route automatically once the
    // /article/:id route exists.
    _router.routeInformationProvider.addListener(_handleDeepLink);
  }

  @override
  void dispose() {
    _router.routeInformationProvider.removeListener(_handleDeepLink);
    super.dispose();
  }

  void _handleDeepLink() {
    final information = _router.routeInformationProvider.value;
    final target = information.uri.path;
    final current = _router.routerDelegate.currentConfiguration.fullPath;
    if (target != current && target.isNotEmpty) {
      _router.go(information.uri.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp.router(
      title: 'NewsAI',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      scrollBehavior: const AppScrollBehavior(),
      initialBinding: AppBinding(),
      routeInformationParser: _router.routeInformationParser,
      routerDelegate: _router.routerDelegate,
      routeInformationProvider: _router.routeInformationProvider,
      backButtonDispatcher: _router.backButtonDispatcher,
    );
  }
}
