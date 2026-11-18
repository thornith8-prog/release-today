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
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp.router(
      title: 'Release Today',
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
