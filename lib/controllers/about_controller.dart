import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/models/setting.dart';
import '../data/repositories/settings_repository.dart';

/// Loads the "about us" setting (`GET /settings/about-us`) and exposes it
/// reactively. Falls back to static content when the backend has no entry.
class AboutController extends GetxController {
  final ApiSettingsRepository repository;

  AboutController(this.repository);

  static final Map<String, Setting> _cache = <String, Setting>{};

  final Rx<Setting?> setting = Rx<Setting?>(null);
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString(null);

  @override
  void onInit() {
    super.onInit();
    if (_cache.containsKey('about-us')) {
      setting.value = _cache['about-us']!;
    } else {
      loadAbout();
    }
  }

  /// Loads the about-us setting in the background. The page always renders its
  /// bundled static content immediately, so this never leaves the screen blank
  /// or stuck on a spinner. On failure the static content stays on screen.
  Future<void> loadAbout({bool force = false}) async {
    if (!force && _cache.containsKey('about-us')) {
      setting.value = _cache['about-us']!;
      return;
    }

    try {
      isLoading.value = true;
      error.value = null;
      final result = await repository.getSetting('about-us');
      _cache['about-us'] = result;
      setting.value = result;
    } catch (e, st) {
      debugPrint('Failed to load about us: $e\n$st');
      // Silent fallback: keep showing the bundled static content.
    } finally {
      isLoading.value = false;
    }
  }

  @visibleForTesting
  static void clearCache() => _cache.clear();
}
