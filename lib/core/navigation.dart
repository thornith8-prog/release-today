import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../controllers/app_controller.dart';
import '../controllers/search_bar_controller.dart';
import '../data/models/article.dart';

/// Context-free navigation so controllers can navigate too.
/// `router` is assigned once in app.dart.
class AppNav {
  AppNav._();

  static late GoRouter router;

  static void _setSearchTopic(int? topicId) {
    if (Get.isRegistered<SearchBarController>()) {
      Get.find<SearchBarController>().setActiveTopic(topicId);
    }
  }

  static void goHome() {
    router.go('/');
  }

  /// Opens the paginated "more news" screen.
  static void goMore() {
    router.go('/more');
  }

  static void goAbout() {
    router.go('/about');
  }

  static void goWhatWeDo() {
    router.go('/what-we-do');
  }

  static void goTerms() {
    router.go('/terms');
  }

  static void goPrivacy() {
    router.go('/privacy');
  }

  /// Records the query in "Recent" and opens the results page.
  /// When [topicId] is provided (because the user selected a topic item),
  /// it is included in the `/search` query parameters.
  static void goSearch(String query, {int? topicId}) {
    final q = query.trim();
    if (q.isEmpty) return;
    _setSearchTopic(topicId);
    if (Get.isRegistered<AppController>()) {
      Get.find<AppController>().addRecent(q);
    }
    router.go(
      Uri(
        path: '/search',
        queryParameters: {
          'q': q,
          if (topicId != null) 'topicId': '$topicId',
        },
      ).toString(),
    );
  }

  /// Opens the article detail page for a shared article.
  static void goArticle(ArticleData article) {
    final id = article.id;
    if (id == null) return;
    _setSearchTopic(null);
    router.push('/article/$id', extra: article);
  }

  /// Opens the Telegram Mini App support page.
  static void goTelegramSupport() {
    router.go('/telegram-support');
  }

  /// Opens the paginated entries page for a topic.
  static void goTopicEntries(int topicId, String label) {
    _setSearchTopic(topicId);
    if (Get.isRegistered<AppController>()) {
      Get.find<AppController>().addRecent(label);
    }
    router.go(
      Uri(
        path: '/topics/$topicId/entries',
        queryParameters: {'label': label},
      ).toString(),
    );
  }
}
