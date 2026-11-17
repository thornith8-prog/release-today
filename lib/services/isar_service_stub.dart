import '../data/models/setting.dart';

class IsarService {
  final Map<String, Setting> _fallbackStore = {};

  bool get isOpen => false;

  Future<void> init({String? directory, String name = 'newsai_db', dynamic testInstance}) async {
    // No-op for web – use in‑memory fallback only.
  }

  Future<Setting?> getSettingBySlug(String slug) async {
    return _fallbackStore[slug];
  }

  Future<List<Setting>> getAllSettings() async {
    return _fallbackStore.values.toList();
  }

  Future<void> putSetting(Setting setting) async {
    _fallbackStore[setting.slug] = setting;
  }

  Future<void> putAllSettings(List<dynamic> settings) async {
    for (final s in settings) {
      _fallbackStore[s.slug] = s;
    }
  }

  Future<void> close({bool deleteFromDisk = false}) async {
    _fallbackStore.clear();
  }
}
