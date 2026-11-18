import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/models/setting.dart';
import '../data/repositories/news_repository.dart';
import '../services/isar_service.dart';

/// Loads the "terms" setting (`terms`) cache-first from [IsarService], then
/// refreshes after [ApiNewsRepository.syncComplete] finishes.
class TermController extends GetxController {
  final IsarService service;
  final ApiNewsRepository repository;

  TermController({required this.service, required this.repository});

  final Rx<Setting?> setting = Rx<Setting?>(null);
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString(null);

  @override
  void onInit() {
    super.onInit();
    loadTerm();
  }

  /// Reads any cached setting immediately so navigation is instant, then waits
  /// for the background API sync and updates if newer content arrived.
  Future<void> loadTerm() async {
    try {
      isLoading.value = true;
      error.value = null;

      final cached = await service.getSettingBySlug('terms');
      if (cached != null) {
        setting.value = cached;
        isLoading.value = false;
      }

      await repository.syncComplete;

      final synced = await service.getSettingBySlug('terms');
      if (synced != null && _hasChanged(setting.value, synced)) {
        setting.value = synced;
      }
    } catch (e, st) {
      debugPrint('Failed to load terms: $e\n$st');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  bool _hasChanged(Setting? current, Setting next) {
    if (current == null) return true;
    return current.title != next.title ||
        current.contentHtml != next.contentHtml ||
        current.updatedAt != next.updatedAt;
  }

  @visibleForTesting
  static void clearCache() {}
}
