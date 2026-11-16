import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/models/article.dart';
import '../data/repositories/news_repository.dart';

/// Shared loading / error / data state for any list of articles.
abstract class ArticlesController extends GetxController {
  ArticlesController(this.repository);

  final ApiNewsRepository repository;

  final articles = <ArticleData>[].obs;
  final isLoading = true.obs;
  final error = RxnString();

  Future<Articles> fetch();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final response = await fetch();
      debugPrint('Fetch news data: ${response.data?.length ?? 0} articles');
      articles.assignAll(response.data ?? []);
    } catch (e, st) {
      debugPrint('Failed to load articles: $e\n$st');
      final msg = e.toString().trim();
      error.value = msg.isEmpty ? 'Failed to load articles.' : msg;
    } finally {
      isLoading.value = false;
    }
  }
}
