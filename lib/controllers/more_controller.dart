import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/models/article.dart';
import '../data/repositories/news_repository.dart';
import 'home_controller.dart';

/// Paginated "more" news. Loads `limit` articles per page via `skip` and
/// appends each subsequent page instead of replacing the list.
class MoreController extends GetxController {
  MoreController(this.repository);

  final ApiNewsRepository repository;

  final articles = <ArticleData>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();

  int _skip = 0;
  static const int _limit = 20;

  bool _lastPageFull = true;
  bool _fetching = false;

  @override
  void onInit() {
    super.onInit();
    syncWithHomeController();
  }

  /// Seeds articles from [HomeController] if HomeController has already
  /// fetched the latest news for the home page. This avoids re-fetching the
  /// same 20 articles when navigating from Home to More and prevents the user
  /// from being stuck staring at a loading view.
  void syncWithHomeController() {
    if (articles.isEmpty && Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      if (homeController.articles.isNotEmpty) {
        articles.assignAll(homeController.articles);
        _skip = homeController.articles.length;
        _lastPageFull = homeController.articles.length >= _limit;
        error.value = null;
        isLoading.value = false;
      }
    }
  }

  /// First page: resets offset and replaces the article list.
  ///
  /// No-op while a fetch is already in flight. If [force] is false and articles
  /// can be seeded from [HomeController], seeds from HomeController instead of
  /// an unnecessary network roundtrip.
  Future<void> load({bool force = false}) async {
    if (!force) {
      syncWithHomeController();
      if (articles.isNotEmpty) return;
    }
    if (_fetching) return;
    _fetching = true;
    isLoading.value = true;
    error.value = null;
    _skip = 0;
    _lastPageFull = true;
    try {
      final response = await repository.latest(skip: _skip, limit: _limit);
      final newArticles = response.data ?? [];
      articles.assignAll(newArticles);
      if (newArticles.length < _limit) {
        _lastPageFull = false;
      } else {
        _skip = newArticles.length;
      }
    } catch (e, st) {
      debugPrint('Failed to load more articles: $e\n$st');
      final msg = e.toString().trim();
      error.value = msg.isEmpty ? 'Failed to load articles.' : msg;
    } finally {
      isLoading.value = false;
      _fetching = false;
    }
  }

  /// Subsequent pages: appends to the list and advances the offset.
  Future<void> loadMore() async {
    // Prevent concurrent fetches or loading when no more pages.
    if (_fetching || isLoading.value || isLoadingMore.value || !_lastPageFull) return;
    _fetching = true;
    isLoadingMore.value = true;
    try {
      final response = await repository.latest(skip: _skip, limit: _limit);
      final newArticles = response.data ?? [];
      articles.addAll(newArticles);
      if (newArticles.length < _limit) {
        _lastPageFull = false;
      } else {
        _skip += newArticles.length;
      }
    } catch (e, st) {
      debugPrint('Failed to load more articles: $e\\n$st');
      final msg = e.toString().trim();
      error.value = msg.isEmpty ? 'Failed to load articles.' : msg;
    } finally {
      isLoadingMore.value = false;
      _fetching = false;
    }
  }
}
