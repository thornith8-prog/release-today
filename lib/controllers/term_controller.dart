import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/models/setting.dart';
import '../data/repositories/settings_repository.dart';

/// Loads the "terms" setting (`terms`) from Isar (synced with remote)
/// and exposes it reactively. Falls back to static content when not available.
class TermController extends GetxController {
  final ApiSettingsRepository repository;

  TermController(this.repository);

  final Rx<Setting?> setting = Rx<Setting?>(null);
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString(null);

  @override
  void onInit() {
    super.onInit();
    loadTerms();
  }

  /// Loads the terms setting from Isar in the background. The page renders
  /// bundled static content immediately until loaded.
  Future<void> loadTerms({bool force = false}) async {
    try {
      isLoading.value = true;
      error.value = null;
      if (force) {
        await repository.syncSettings();
      }
      final result = await repository.getSetting('terms');
      setting.value = result;
    } catch (e, st) {
      debugPrint('Failed to load terms: $e\n$st');
      // Silent fallback: keep showing the bundled static content.
    } finally {
      isLoading.value = false;
    }
  }

  // Alias for backward compatibility
  Future<void> loadAbout({bool force = false}) => loadTerms(force: force);

  @visibleForTesting
  static void clearCache() {}
}
