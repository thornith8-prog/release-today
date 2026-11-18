import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:newsai/core/env.dart';
import 'package:newsai/data/repositories/partner_repository.dart';

import '../../services/api_client.dart';
import '../../services/isar_service.dart';
import '../models/article.dart';
import '../models/partner.dart';
import '../models/setting.dart';
import 'chat_history.dart';

class NewsApiException implements Exception {
  NewsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class NewsRepository {
  Future<Articles> latest({int skip = 0, int limit = 20});

  Future<Articles> search(String query, {int limit = 20, int? topicId});

  Future<ChatHistory> getChatByTopicId(int topicId,
      {int skip = 0, int limit = 20});

  Future<Partner> partners({int page = 1, int limit = 50});

  Future<List<Setting>> syncSettings();
}

class ApiNewsRepository implements NewsRepository {
  final ApiClient api;
  final IsarService localService;
  final Completer<void> _syncCompleter = Completer<void>();

  /// Completes when [syncSettings] finishes (success or failure), so
  /// controllers can await it before reading from Isar.
  Future<void> get syncComplete => _syncCompleter.future;

  ApiNewsRepository(this.api, this.localService);

  @override
  String toString() => 'ApiNewsRepository';

  Articles _parseArticles(Response<dynamic> response) {
    if (response.status.hasError || response.body == null) {
      final detail = response.statusText?.trim();
      final code = response.statusCode;
      throw NewsApiException(
        (detail != null && detail.isNotEmpty)
            ? detail
            : 'Failed to load articles (${code ?? "network/CORS error"})',
      );
    }

    final raw = response.body;
    Map<String, dynamic> json;
    try {
      json = switch (raw) {
        Map<String, dynamic> m => m,
        Map m => Map<String, dynamic>.from(m),
        String s => jsonDecode(s) as Map<String, dynamic>,
        _ => throw NewsApiException(
            'Unexpected response format: ${raw.runtimeType}'),
      };
    } on FormatException {
      throw NewsApiException('Failed to parse articles response.');
    }
    return Articles.fromJson(json);
  }

  @override
  Future<Articles> latest({int skip = 0, int limit = 20}) async {
    final response = await api.get(
      Env.latestPath,
      query: {'skip': '$skip', 'limit': '$limit'},
    );
    return _parseArticles(response);
  }

  @override
  Future<Articles> search(String query, {int limit = 10, int? topicId}) async {
    final queryParams = <String, dynamic>{
      Env.searchParam: query,
      'limit': '$limit',
      if (topicId != null) 'topicId': '$topicId',
    };
    final response = await api.get(
      Env.searchPath,
      query: queryParams,
    );
    return _parseArticles(response);
  }

  @override
  Future<ChatHistory> getChatByTopicId(int topicId,
      {int skip = 0, int limit = 20}) async {
    final queryParams = <String, dynamic>{'limit': '$limit', 'offset': skip};
    final basePath =
        Env.chatHistory.endsWith('/') ? Env.chatHistory : '${Env.chatHistory}/';
    final response = await api.get(
      '$basePath$topicId/entries',
      query: queryParams,
    );

    if (response.status.hasError || response.body == null) {
      final detail = response.statusText?.trim();
      final code = response.statusCode;
      throw NewsApiException(
        (detail != null && detail.isNotEmpty)
            ? detail
            : 'Failed to load chat history (${code ?? "network/CORS error"})',
      );
    } else {
      final raw = response.body;
      final Map<String, dynamic> json = switch (raw) {
        Map<String, dynamic> m => m,
        Map m => Map<String, dynamic>.from(m),
        String s => jsonDecode(s) as Map<String, dynamic>,
        _ => throw NewsApiException(
            'Unexpected response format: ${raw.runtimeType}'),
      };
      return ChatHistory.fromJson(json);
    }
  }

  @override
  Future<Partner> partners({int page = 1, int limit = 50}) async {
    final response = await api.get(
      Env.partnersPath,
      query: {'page': '$page', 'limit': '$limit'},
    );
    return _parsePartners(response);
  }

  Partner _parsePartners(Response<dynamic> response) {
    if (response.status.hasError || response.body == null) {
      final detail = response.statusText?.trim();
      final code = response.statusCode;
      throw PartnerApiException(
        (detail != null && detail.isNotEmpty)
            ? detail
            : 'Failed to load partners (${code ?? "network/CORS error"})',
      );
    }

    final raw = response.body;
    Map<String, dynamic> json;
    try {
      json = switch (raw) {
        Map<String, dynamic> m => m,
        Map m => Map<String, dynamic>.from(m),
        String s => jsonDecode(s) as Map<String, dynamic>,
        _ => throw PartnerApiException(
            'Unexpected response format: ${raw.runtimeType}'),
      };
    } on FormatException {
      throw PartnerApiException('Failed to parse partners response.');
    }
    return Partner.fromJson(json);
  }

  @override
  Future<List<Setting>> syncSettings() async {
    try {
      final response = await api.get(Env.settingsPath);
    final json = _decodeResponse(response);
    final rawList = json['data'];
    if (rawList is! List) {
      return await localService.getAllSettings();
    }

    final List<Setting> toUpdate = [];

    // Check all settings in parallel rather than one awaited round-trip each.
    final localSettings = await Future.wait(
      rawList.whereType<Map>().map(
        (item) async {
          final remote = Setting.fromJson(Map<String, dynamic>.from(item));
          final local = await localService.getSettingBySlug(remote.slug);
          return MapEntry(remote, local);
        },
      ),
    );

    for (final entry in localSettings) {
      final remoteSetting = entry.key;
      final localSetting = entry.value;

      if (localSetting == null) {
        toUpdate.add(remoteSetting);
        continue;
      }

      final remoteUpdate = remoteSetting.updatedAt;
      final localUpdate = localSetting.updatedAt;

      final shouldUpdate = localUpdate == null ||
          (remoteUpdate != null && remoteUpdate.isAfter(localUpdate)) ||
          (remoteUpdate == null &&
              (remoteSetting.title != localSetting.title ||
                  remoteSetting.contentHtml != localSetting.contentHtml));

      if (shouldUpdate) {
        // Preserve the local id so Isar updates the existing row in place.
        remoteSetting.id = localSetting.id;
        toUpdate.add(remoteSetting);
      }
    }

    if (toUpdate.isNotEmpty) {
      await localService.putAllSettings(toUpdate);
    }

    return await localService.getAllSettings();
  } finally {
    if (!_syncCompleter.isCompleted) {
      _syncCompleter.complete();
    }
  }
  }

  Map<String, dynamic> _decodeResponse(Response<dynamic> response) {
    if (response.status.hasError || response.body == null) {
      final detail = response.statusText?.trim();
      final code = response.statusCode;
      throw NewsApiException(
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
      _ => throw NewsApiException(
          'Unexpected response format: ${raw.runtimeType}'),
    };
  }
}
