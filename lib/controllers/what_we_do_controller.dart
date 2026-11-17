import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:newsai/data/models/setting.dart';
import 'package:newsai/data/repositories/news_repository.dart';
import 'package:newsai/services/isar_service.dart';

/// Loads the "what we do" setting (`what-we-do`) from Isar (synced with remote
/// by [AppBinding] on startup) and exposes it reactively. Falls back to static
/// content when not available.
class WhatWeDoController extends GetxController {
  final IsarService service;
  final ApiNewsRepository repository;

  WhatWeDoController({required this.service, required this.repository});

  final Rx<Setting?> setting = Rx<Setting?>(null);
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString(null);

  @override
  void onInit() {
    super.onInit();
    loadWhatWeDo();
  }

  /// Waits for the API → Isar sync to finish, then reads the what-we-do
  /// setting from local Isar. Does not call the network itself.
  Future<void> loadWhatWeDo() async {
    try {
      isLoading.value = true;
      error.value = null;

      // Ensure settings have been synced to Isar before reading.
      await repository.syncComplete;

      final result = await service.getSettingBySlug('what-we-do');
      setting.value = result;
    } catch (e, st) {
      debugPrint('Failed to load what we do: $e\n$st');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  @visibleForTesting
  static void clearCache() {}
}
