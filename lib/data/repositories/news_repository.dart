import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:newsai/core/env.dart';

import '../../services/api_client.dart';
import '../models/article.dart';
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
}

class ApiNewsRepository implements NewsRepository {
  final ApiClient api;

  ApiNewsRepository(this.api);

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
    final Map<String, dynamic> json = switch (raw) {
      Map<String, dynamic> m => m,
      Map m => Map<String, dynamic>.from(m),
      String s => jsonDecode(s) as Map<String, dynamic>,
      _ => throw NewsApiException(
          'Unexpected response format: ${raw.runtimeType}'),
    };
    return Articles.fromJson(json);
  }

  @override
  Future<Articles> latest({int skip = 0, int limit = 10}) async {
    final response = await api.get(
      Env.latestPath,
      query: {'skip': '$skip', 'limit': '$limit'},
    );

    printError(info: 'Fetch articles: ${response.headers.toString()}');
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
}
