import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:newsai/controllers/search_bar_controller.dart';

import '../data/models/article.dart';
import '../data/models/partner.dart';
import '../data/repositories/news_repository.dart';

/// Latest news for the home carousel. Permanent, so returning home does not refetch.
class HomeController extends GetxController {
  HomeController({required this.repository});

  final ApiNewsRepository repository;

  final articles = <ArticleData>[].obs;
  final isLoading = true.obs;
  final error = RxnString();
  final partners = <PartnerItems>[].obs;
  final isLoadingPartner = true.obs;
  final errorPartner = RxnString();
  @override
  void onInit() {
    super.onInit();
    load();
    loadPartner();
    if (Get.isRegistered<SearchBarController>()) {
      Get.find<SearchBarController>().clearActiveTopic();
    }
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final response = await repository.latest(limit: 12);
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

  Future<void> loadPartner() async {
    isLoadingPartner.value = true;
    errorPartner.value = null;
    try {
      final response = await repository.partners(limit: 6);
      isLoadingPartner.value = false;
      debugPrint('Fetch partner data: ${response.data?.items ?? 0} articles');
      partners.assignAll(response.data?.items ?? []);
    } catch (e, st) {
      debugPrint('Failed to load articles: $e\n$st');
      final msg = e.toString().trim();
      errorPartner.value = msg.isEmpty ? 'Failed to load articles.' : msg;
    } finally {
      isLoadingPartner.value = false;
    }
  }
}
