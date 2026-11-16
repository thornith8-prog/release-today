import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../data/models/article.dart';
import 'features/article/article_detail_page.dart';
import 'features/home/home_page.dart';
import 'features/more/about_page.dart';
import 'features/more/more_page.dart';
import 'features/more/privacy_page.dart';
import 'features/more/term_page.dart';
import 'features/more/what_we_do_page.dart';
import 'features/results/results_page.dart';
import 'features/shell/app_shell.dart';

/// Every page swaps instantly (no slide/fade). Only the content inside the
/// shell changes, so a page transition adds no value here.
Page<void> _noTransition(GoRouterState state, Widget child) =>
    NoTransitionPage<void>(key: state.pageKey, child: child);

GoRouter buildRouter() {
  return GoRouter(
    routes: [
      // The shell keeps the sidebar, top bar and search bar mounted across pages.
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                _noTransition(state, const HomePage()),
          ),
          GoRoute(
            path: '/more',
            pageBuilder: (context, state) =>
                _noTransition(state, const MorePage()),
          ),
          GoRoute(
            path: '/about',
            pageBuilder: (context, state) =>
                _noTransition(state, const AboutPage()),
          ),
          GoRoute(
            path: '/what-we-do',
            pageBuilder: (context, state) =>
                _noTransition(state, const WhatWeDoPage()),
          ),
          GoRoute(
            path: '/privacy',
            pageBuilder: (context, state) =>
                _noTransition(state, const PrivacyPage()),
          ),
          GoRoute(
            path: '/terms',
            pageBuilder: (context, state) =>
                _noTransition(state, const TermPage()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) {
              final query = state.uri.queryParameters['q'] ?? '';
              final searchTopicId =
                  int.tryParse(state.uri.queryParameters['topicId'] ?? '');
              return _noTransition(
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
              return _noTransition(
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
              return _noTransition(
                state,
                ArticleDetailPage(
                  article: article,
                  articleId: state.pathParameters['id'] ?? '',
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
}
