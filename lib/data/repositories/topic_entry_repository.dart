import 'dart:convert';

import 'package:get/get.dart';

import '../../core/env.dart';
import '../models/topic_entry.dart';

import '../../services/api_client.dart';

class TopicEntryApiException implements Exception {
  TopicEntryApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fetch entries for a topic: `GET /search-topic/topics/{id}/entries`.
abstract class TopicEntryRepository {
  Future<TopicEntries> entries({
    required int topicId,
    int limit = 10,
    int offset = 0,
  });
}

/// Backed by `GET /search-topic/topics/{id}/entries`. The bearer token is
/// injected by [ApiClient] from the persisted session.
class ApiTopicEntryRepository implements TopicEntryRepository {
  final ApiClient api;

  ApiTopicEntryRepository(this.api);

  TopicEntries _parseEntries(Response<dynamic> response) {
    if (response.status.hasError || response.body == null) {
      final detail = response.statusText?.trim();
      final code = response.statusCode;
      throw TopicEntryApiException(
        (detail != null && detail.isNotEmpty)
            ? detail
            : 'Failed to load topic entries (${code ?? "network/CORS error"})',
      );
    }

    final raw = response.body;
    final Map<String, dynamic> json = switch (raw) {
      Map<String, dynamic> m => m,
      Map m => Map<String, dynamic>.from(m),
      String s => jsonDecode(s) as Map<String, dynamic>,
      _ => throw TopicEntryApiException('Unexpected response format: ${raw.runtimeType}'),
    };
    return TopicEntries.fromJson(json);
  }

  @override
  Future<TopicEntries> entries({
    required int topicId,
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await api.get(
      '${Env.topicsPath}/$topicId/entries',
      query: {'limit': '$limit', 'offset': '$offset'},
    );
    return _parseEntries(response);
  }
}
