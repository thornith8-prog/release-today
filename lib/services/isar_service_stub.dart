import 'package:get_storage/get_storage.dart';

import '../data/models/setting.dart';

/// Web-compatible settings store backed by [GetStorage] (with a shared
/// in-memory fallback for environments where storage has not been initialized)
/// so public informational settings (`about-us`, `what-we-do`, `privacy`,
/// `terms`) persist across page reloads on Flutter Web.
class IsarService {
  static const _storageKey = 'settings.cache.v1';
  static final Map<String, Map<String, dynamic>> _sharedFallback = {};

  final Map<String, Setting> _cache = {};
  bool _hydrated = false;

  bool get isOpen => false;

  Future<void> init({
    String? directory,
    String name = 'newsai_db',
    dynamic testInstance,
  }) async {
    _hydrateIfNeeded();
  }

  void _hydrateIfNeeded() {
    if (_hydrated) return;
    _hydrated = true;

    Map<String, dynamic>? rawMap;
    try {
      final stored = GetStorage().read(_storageKey);
      if (stored is Map) {
        rawMap = Map<String, dynamic>.from(stored);
      }
    } catch (_) {
      // GetStorage not initialized in unit test environment; use shared fallback.
    }

    rawMap ??= Map<String, dynamic>.from(_sharedFallback);

    for (final entry in rawMap.entries) {
      final value = entry.value;
      if (value is Map) {
        final setting = Setting.fromJson(Map<String, dynamic>.from(value));
        if (setting.slug.isNotEmpty) {
          _cache[setting.slug] = setting;
        }
      }
    }
  }

  void _persist() {
    final serialized = <String, Map<String, dynamic>>{
      for (final entry in _cache.entries) entry.key: entry.value.toJson(),
    };
    _sharedFallback
      ..clear()
      ..addAll(serialized);
    try {
      GetStorage().write(_storageKey, serialized);
    } catch (_) {
      // Ignore storage write errors in non-initialized test environments.
    }
  }

  Future<Setting?> getSettingBySlug(String slug) async {
    _hydrateIfNeeded();
    return _cache[slug];
  }

  Future<List<Setting>> getAllSettings() async {
    _hydrateIfNeeded();
    return _cache.values.toList();
  }

  Future<void> putSetting(Setting setting) async {
    _hydrateIfNeeded();
    _cache[setting.slug] = setting;
    _persist();
  }

  Future<void> putAllSettings(List<dynamic> settings) async {
    _hydrateIfNeeded();
    for (final s in settings) {
      if (s is Setting) {
        _cache[s.slug] = s;
      }
    }
    _persist();
  }

  Future<void> close({bool deleteFromDisk = false}) async {
    _cache.clear();
    _hydrated = false;
    if (deleteFromDisk) {
      _sharedFallback.clear();
      try {
        await GetStorage().remove(_storageKey);
      } catch (_) {}
    }
  }
}
