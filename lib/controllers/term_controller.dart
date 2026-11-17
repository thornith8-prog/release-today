import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/models/setting.dart';
import '../data/repositories/news_repository.dart';
import '../services/isar_service.dart';

/// Loads the "terms" setting (`terms`) from Isar (synced with remote
/// by [AppBinding] on startup) and exposes it reactively. Falls back to static
/// content when not available.
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

  /// Waits for the API → Isar sync to finish, then reads the terms setting
  /// from local Isar. Does not call the network itself.
  Future<void> loadTerm() async {
    try {
      isLoading.value = true;
      error.value = null;

      await repository.syncComplete;

      final result = await service.getSettingBySlug('terms');
      setting.value = result;
    } catch (e, st) {
      debugPrint('Failed to load terms: $e\n$st');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  @visibleForTesting
  static void clearCache() {}
}
