import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../services/api_client.dart';
import '../../services/isar_service.dart';
import '../models/setting.dart';

class SettingApiException implements Exception {
  final String message;
  SettingApiException(this.message);

  @override
  String toString() => message;
}

abstract class SettingsRepository {
  Future<Setting> getSetting(String slug);
  Future<List<Setting>> syncSettings();
}

/// Backed by `GET /settings` and Isar persistent storage.
class ApiSettingsRepository implements SettingsRepository {
  final ApiClient api;
  final IsarService isarService;

  ApiSettingsRepository(this.api, this.isarService);

  Map<String, dynamic> _decodeResponse(Response<dynamic> response) {
    if (response.status.hasError || response.body == null) {
      final detail = response.statusText?.trim();
      final code = response.statusCode;
      throw SettingApiException(
        (detail != null && detail.isNotEmpty)
            ? detail
            : 'Failed to load setting (${code ?? "network/CORS error"})',
      );
    }

    final raw = response.body;
    return switch (raw) {
      Map<String, dynamic> m => m,
      Map m => Map<String, dynamic>.from(m),
      String s => jsonDecode(s) as Map<String, dynamic>,
      _ => throw SettingApiException(
          'Unexpected response format: ${raw.runtimeType}'),
    };
  }

  /// Synchronizes settings from the remote API endpoint `GET /settings`.
  /// Updates local records in Isar if the incoming record's `updated_at`
  /// is newer than the existing record, or if no local record exists yet.
  @override
  Future<List<Setting>> syncSettings() async {
    try {
      final response = await api.get('/settings');
      final json = _decodeResponse(response);

      final rawList = json['data'];
      if (rawList is! List) {
        return await isarService.getAllSettings();
      }

      final List<Setting> toUpdate = [];

      for (final item in rawList) {
        if (item is! Map) continue;
        final remoteSetting = Setting.fromJson(Map<String, dynamic>.from(item));
        final localSetting = await isarService.getSettingBySlug(remoteSetting.slug);

        if (localSetting == null) {
          toUpdate.add(remoteSetting);
        } else {
          // Compare update_at
          final remoteUpdate = remoteSetting.updatedAt;
          final localUpdate = localSetting.updatedAt;

          if (remoteUpdate != null) {
            if (localUpdate == null || remoteUpdate.isAfter(localUpdate)) {
              // Remote is newer, preserve local id if needed so Isar updates in place
              remoteSetting.id = localSetting.id;
              toUpdate.add(remoteSetting);
            }
          }
        }
      }

      if (toUpdate.isNotEmpty) {
        await isarService.putAllSettings(toUpdate);
      }
    } catch (e, st) {
      debugPrint('Settings sync failed: $e\n$st');
    }

    return await isarService.getAllSettings();
  }

  /// Loads the setting with [slug] from Isar.
  /// If not found in Isar, attempts to sync from the backend, then returns the result.
  @override
  Future<Setting> getSetting(String slug) async {
    // 1. Try to read from Isar first
    final local = await isarService.getSettingBySlug(slug);
    if (local != null) {
      return local;
    }

    // 2. Not in Isar yet, attempt sync
    await syncSettings();
    final afterSync = await isarService.getSettingBySlug(slug);
    if (afterSync != null) {
      return afterSync;
    }

    // 3. Fallback to single endpoint /settings/$slug if available
    try {
      final response = await api.get('/settings/$slug');
      final json = _decodeResponse(response);
      final setting = Setting.fromJson(json);
      await isarService.putSetting(setting);
      return setting;
    } catch (_) {
      throw SettingApiException('Setting for "$slug" not found in local storage or remote.');
    }
  }
}
