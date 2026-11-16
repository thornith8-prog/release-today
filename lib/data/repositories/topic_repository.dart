import 'dart:convert';

import 'package:get/get.dart';

import '../../core/env.dart';
import '../models/topic.dart';

import '../../services/api_client.dart';

class TopicApiException implements Exception {
  TopicApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fetch topics belonging to the signed-in user.
abstract class TopicRepository {
  /// Returns the first page of topics ([limit] items from [offset]).
  Future<Topics> topics({int limit = 10, int offset = 0});

  /// Deletes a topic by its [topicId].
  Future<bool> deleteTopic(int topicId);
}

/// Backed by `GET /search-topic/topics`. The bearer token is injected by
/// [ApiClient] from the persisted session, so a signed-in user's own topics
/// are returned. A 401 triggers a token refresh automatically.
class ApiTopicRepository implements TopicRepository {
  final ApiClient api;

  ApiTopicRepository(this.api);

  Topics _parseTopics(Response<dynamic> response) {
    if (response.status.hasError || response.body == null) {
      final detail = response.statusText?.trim();
      final code = response.statusCode;
      throw TopicApiException(
        (detail != null && detail.isNotEmpty)
            ? detail
            : 'Failed to load topics (${code ?? "network/CORS error"})',
      );
    }

    final raw = response.body;
    final Map<String, dynamic> json = switch (raw) {
      Map<String, dynamic> m => m,
      Map m => Map<String, dynamic>.from(m),
      String s => jsonDecode(s) as Map<String, dynamic>,
      _ => throw TopicApiException('Unexpected response format: ${raw.runtimeType}'),
    };
    return Topics.fromJson(json);
  }

  @override
  Future<Topics> topics({int limit = 10, int offset = 0}) async {
    final response = await api.get(
      Env.topicsPath,
      query: {'limit': '$limit', 'offset': '$offset'},
    );
    return _parseTopics(response);
  }

  @override
  Future<bool> deleteTopic(int topicId) async {
    final response = await api.delete('${Env.topicsPath}/$topicId');
    if (response.status.hasError) {
      final detail = response.statusText?.trim();
      final code = response.statusCode;
      throw TopicApiException(
        (detail != null && detail.isNotEmpty)
            ? detail
            : 'Failed to delete topic (${code ?? "network/CORS error"})',
      );
    }
    return true;
  }
}
