import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/models/article.dart';
import '../data/repositories/news_repository.dart';

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

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// First page: resets offset and replaces the article list.
  Future<void> load() async {
    _skip = 0;
    _lastPageFull = true;
    articles.clear();
    await _fetch(replace: true);
  }

  /// Subsequent pages: appends to the list and advances the offset.
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !_lastPageFull) return;
    isLoadingMore.value = true;
    await _fetch(replace: false);
    isLoadingMore.value = false;
  }

  Future<void> _fetch({required bool replace}) async {
    error.value = null;
    try {
      final response = await repository.latest(skip: _skip, limit: _limit);
      final newArticles = response.data ?? [];
      if (replace) {
        articles.assignAll(newArticles);
      } else {
        articles.addAll(newArticles);
      }
      if (newArticles.length < _limit) {
        _lastPageFull = false;
      } else {
        _skip += newArticles.length;
      }
    } catch (e, st) {
      debugPrint('Failed to load more articles: $e\n$st');
      final msg = e.toString().trim();
      error.value = msg.isEmpty ? 'Failed to load articles.' : msg;
    }
  }
}
