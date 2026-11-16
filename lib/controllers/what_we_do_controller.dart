import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/models/setting.dart';
import '../data/repositories/settings_repository.dart';

/// Loads the "what we do" setting (`GET /settings/what-we-do`) and exposes it
/// reactively. Falls back to static content when the backend has no entry.
class WhatWeDoController extends GetxController {
  final ApiSettingsRepository repository;

  WhatWeDoController(this.repository);

  static final Map<String, Setting> _cache = <String, Setting>{};

  final Rx<Setting?> setting = Rx<Setting?>(null);
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString(null);

  @override
  void onInit() {
    super.onInit();
    if (_cache.containsKey('what-we-do')) {
      setting.value = _cache['what-we-do']!;
    } else {
      loadAbout();
    }
  }

  /// Loads the what-we-do setting in the background. The page always renders
  /// its bundled static content immediately, so this never leaves the screen
  /// blank or stuck on a spinner. On failure the static content stays on screen.
  Future<void> loadAbout({bool force = false}) async {
    if (!force && _cache.containsKey('what-we-do')) {
      setting.value = _cache['what-we-do']!;
      return;
    }

    try {
      isLoading.value = true;
      error.value = null;
      final result = await repository.getSetting('what-we-do');
      _cache['what-we-do'] = result;
      setting.value = result;
    } catch (e, st) {
      debugPrint('Failed to load what we do: $e\n$st');
      // Silent fallback: keep showing the bundled static content.
    } finally {
      isLoading.value = false;
    }
  }

  @visibleForTesting
  static void clearCache() => _cache.clear();
}
