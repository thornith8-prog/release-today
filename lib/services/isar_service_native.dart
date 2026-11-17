import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../data/models/setting.dart';

class IsarService {
  Isar? _isar;
  final Map<String, Setting> _fallbackStore = {};

  bool get isOpen => _isar != null && _isar!.isOpen;

  @visibleForTesting
  Isar? get isarInstance => _isar;

  Future<void> init({
    String? directory,
    String name = 'newsai_db',
    Isar? testInstance,
  }) async {
    if (testInstance != null) {
      _isar = testInstance;
      return;
    }

    if (_isar != null && _isar!.isOpen) {
      return;
    }

    // Web guard removed – native implementation always attempts to open Isar.
    try {
      final existing = Isar.getInstance(name);
      if (existing != null && existing.isOpen) {
        _isar = existing;
        return;
      }

      if (!kIsWeb && directory == null) {
        // When running in Flutter desktop/mobile, directory can be obtained or default to '.'
        directory = '';
      }

      _isar = await Isar.open(
        [SettingSchema],
        directory: directory ?? '',
        name: name,
        inspector: false,
      );
    } catch (e, st) {
      debugPrint('Warning: Could not open Isar database ($e). Using in-memory fallback.\n$st');
    }
  }

  Future<Setting?> getSettingBySlug(String slug) async {
    if (isOpen) {
      return await _isar!.settings.getBySlug(slug);
    }
    return _fallbackStore[slug];
  }

  Future<List<Setting>> getAllSettings() async {
    if (isOpen) {
      return await _isar!.settings.where().findAll();
    }
    return _fallbackStore.values.toList();
  }

  Future<void> putSetting(Setting setting) async {
    if (isOpen) {
      await _isar!.writeTxn(() async {
        await _isar!.settings.putBySlug(setting);
      });
    } else {
      _fallbackStore[setting.slug] = setting;
    }
  }

  Future<void> putAllSettings(List<Setting> settings) async {
    if (isOpen) {
      await _isar!.writeTxn(() async {
        for (final s in settings) {
          await _isar!.settings.putBySlug(s);
        }
      });
    } else {
      for (final s in settings) {
        _fallbackStore[s.slug] = s;
      }
    }
  }

  Future<void> close({bool deleteFromDisk = false}) async {
    if (isOpen) {
      await _isar!.close(deleteFromDisk: deleteFromDisk);
      _isar = null;
    }
    _fallbackStore.clear();
  }
}
