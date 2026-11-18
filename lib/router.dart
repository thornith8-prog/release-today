import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/navigation.dart';
import 'data/models/article.dart';
import 'features/article/article_detail_page.dart';
import 'features/home/home_page.dart';
import 'features/more/about_page.dart';
import 'features/more/more_page.dart';
import 'features/more/privacy_page.dart';
import 'features/more/term_page.dart';
import 'features/more/what_we_do_page.dart';
import 'features/results/results_page.dart';
import 'features/shell/app_shell.dart';
import 'features/support/telegram_support_page.dart';
import 'widgets/pill_button.dart';

bool _isTelegramParam(String segment) =>
    segment.startsWith('tgWebApp') && segment.contains('=');

/// Strips Telegram Mini App launch parameters (`tgWebAppData`,
/// `tgWebAppVersion`, `tgWebAppPlatform`, `tgWebAppThemeParams`, etc.) from a
/// raw route location string.
///
/// Telegram appends these parameters in `window.location.hash` when launching a
/// Mini App (`#tgWebAppData=...`). After `telegram-web-app.js` reads them into
/// `window.Telegram.WebApp` and `sessionStorage`, Flutter Web's hash URL
/// strategy sees that fragment as the initial route name.
///
/// Returns the normalized route (always starting with `/`) when Telegram
/// parameters were present, or `null` when [rawLocation] contains none.
String? sanitizeTelegramRawLocation(String rawLocation) {
  if (!rawLocation.contains('tgWebApp')) return null;

  var value = rawLocation;
  var modified = false;

  // 1. Strip `#tgWebApp...=` fragment appended after a hash route.
  final hashIdx = value.indexOf('#tgWebApp');
  if (hashIdx != -1 && _isTelegramParam(value.substring(hashIdx + 1))) {
    value = value.substring(0, hashIdx);
    modified = true;
  }

  // 2. Entire location is Telegram hash params (`tgWebAppData=...` or `/tgWebAppData=...`).
  final withoutLeadingSlash =
      value.startsWith('/') ? value.substring(1) : value;
  if (_isTelegramParam(withoutLeadingSlash)) {
    return '/';
  }

  final qIdx = value.indexOf('?');
  final ampIdx = value.indexOf('&tgWebApp');

  // 3. Hash-route path with `&tgWebApp...=` appended directly (before any `?`),
  // e.g. `/telegram-support&tgWebAppData=...`.
  if (ampIdx != -1 &&
      (qIdx == -1 || ampIdx < qIdx) &&
      _isTelegramParam(value.substring(ampIdx + 1))) {
    value = value.substring(0, ampIdx);
    modified = true;
    if (value.isEmpty) return '/';
    return value.startsWith('/') ? value : '/$value';
  }

  // 4. Query string containing `tgWebApp*=...` params (e.g. `/search?q=ai&tgWebAppData=...`).
  if (qIdx != -1) {
    final pathPart = value.substring(0, qIdx);
    final queryPart = value.substring(qIdx + 1);

    final keptSegments = <String>[];
    for (final seg in queryPart.split('&')) {
      if (_isTelegramParam(seg)) {
        modified = true;
      } else if (seg.isNotEmpty) {
        keptSegments.add(seg);
      }
    }

    if (!modified) return null;
    final normalizedPath = pathPart.isEmpty
        ? '/'
        : (pathPart.startsWith('/') ? pathPart : '/$pathPart');
    return keptSegments.isEmpty
        ? normalizedPath
        : '$normalizedPath?${keptSegments.join('&')}';
  }

  if (!modified) return null;
  if (value.isEmpty) return '/';
  return value.startsWith('/') ? value : '/$value';
}

/// Smooth, lightweight cross-fade inside [AppShell] so switching sidebar tabs
/// feels fluid without heavy slide/layout cost.
Page<void> _shellPageTransition(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 150),
      reverseTransitionDuration: const Duration(milliseconds: 120),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
        opacity: CurveTween(curve: Curves.easeOut).animate(animation),
        child: child,
      ),
    );

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined, size: 44),
            const SizedBox(height: 12),
            Text(
              'Page not found',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const PillButton(
              label: 'Back to Home',
              filled: true,
              onPressed: AppNav.goHome,
            ),
          ],
        ),
      ),
    );
  }
}

GoRouter buildRouter() {
  final platformRoute =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  final sanitizedInitial = sanitizeTelegramRawLocation(platformRoute);

  return GoRouter(
    initialLocation: sanitizedInitial ?? '/',
    overridePlatformDefaultLocation: sanitizedInitial != null,
    redirect: (context, state) =>
        sanitizeTelegramRawLocation(state.uri.toString()),
    // Render a generic not-found view so raw URLs/tokens are never echoed to UI.
    errorPageBuilder: (context, state) => _shellPageTransition(
      state,
      AppShell(
        currentPath: state.uri.path,
        child: const _NotFoundView(),
      ),
    ),
    routes: [
      // The shell keeps the sidebar, top bar and search bar mounted across pages.
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentPath: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                _shellPageTransition(state, const HomePage()),
          ),
          GoRoute(
            path: '/more',
            pageBuilder: (context, state) =>
                _shellPageTransition(state, const MorePage()),
          ),
          GoRoute(
            path: '/about',
            pageBuilder: (context, state) =>
                _shellPageTransition(state, const AboutPage()),
          ),
          GoRoute(
            path: '/what-we-do',
            pageBuilder: (context, state) =>
                _shellPageTransition(state, const WhatWeDoPage()),
          ),
          GoRoute(
            path: '/privacy',
            pageBuilder: (context, state) =>
                _shellPageTransition(state, const PrivacyPage()),
          ),
          GoRoute(
            path: '/terms',
            pageBuilder: (context, state) =>
                _shellPageTransition(state, const TermPage()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) {
              final query = state.uri.queryParameters['q'] ?? '';
              final searchTopicId =
                  int.tryParse(state.uri.queryParameters['topicId'] ?? '');
              return _shellPageTransition(
                state,
                ResultsPage(
                  key: ValueKey('search-$query-${searchTopicId ?? ""}'),
                  query: query,
                  searchTopicId: searchTopicId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/topics/:topicId/entries',
            pageBuilder: (context, state) {
              final topicId =
                  int.tryParse(state.pathParameters['topicId'] ?? '') ?? 0;
              final topicName = state.uri.queryParameters['label'] ?? 'Topic';
              return _shellPageTransition(
                state,
                ResultsPage(
                  key: ValueKey('topic-$topicId'),
                  topicId: topicId,
                  topicName: topicName,
                ),
              );
            },
          ),
          GoRoute(
            path: '/article/:id',
            pageBuilder: (context, state) {
              final article = state.extra as ArticleData?;
              return _shellPageTransition(
                state,
                ArticleDetailPage(
                  article: article,
                  articleId: state.pathParameters['id'] ?? '',
                ),
              );
            },
          ),
          GoRoute(
            path: '/telegram-support',
            pageBuilder: (context, state) =>
                _shellPageTransition(state, const TelegramSupportPage()),
          ),
        ],
      ),
    ],
  );
}
