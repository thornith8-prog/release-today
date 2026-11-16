import 'dart:convert';

import 'package:get/get.dart';

import '../../services/api_client.dart';
import '../models/setting.dart';

class SettingApiException implements Exception {
  final String message;
  SettingApiException(this.message);

  @override
  String toString() => message;
}

abstract class SettingsRepository {
  Future<Setting> getSetting(String slug);
}

/// Backed by `GET /settings/{slug}`.
class ApiSettingsRepository implements SettingsRepository {
  final ApiClient api;

  ApiSettingsRepository(this.api);

  Setting _parseSetting(Response<dynamic> response) {
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
    final Map<String, dynamic> json = switch (raw) {
      Map<String, dynamic> m => m,
      Map m => Map<String, dynamic>.from(m),
      String s => jsonDecode(s) as Map<String, dynamic>,
      _ => throw SettingApiException(
          'Unexpected response format: ${raw.runtimeType}'),
    };
    return Setting.fromJson(json);
  }

  @override
  Future<Setting> getSetting(String slug) async {
    final response = await api.get('/settings/$slug');
    return _parseSetting(response);
  }
}
