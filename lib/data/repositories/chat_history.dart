import 'dart:convert';

import '../models/article.dart';

class ChatHistory {
  int? code;
  String? status;
  String? message;
  ChatData? data;

  ChatHistory({this.code, this.status, this.message, this.data});

  ChatHistory.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    status = json['status'];
    message = json['message'];
    if (json['data'] is Map) {
      data = ChatData.fromJson(Map<String, dynamic>.from(json['data']));
    } else if (json['data'] is List) {
      data = ChatData.fromJson({
        'items': json['data'],
        'total': (json['data'] as List).length,
      });
    } else {
      data = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class ChatData {
  int? total;
  List<ChatItems>? items;

  ChatData({this.total, this.items});

  ChatData.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    if (json['items'] is List) {
      items = <ChatItems>[];
      for (final v in json['items']) {
        if (v is Map) {
          items!.add(ChatItems.fromJson(Map<String, dynamic>.from(v)));
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total'] = total;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ChatItems {
  int? id;
  int? topicId;
  String? userId;
  String? prompt;
  String? results;
  int? resultCount;
  String? createdAt;

  ChatItems({
    this.id,
    this.topicId,
    this.userId,
    this.prompt,
    this.results,
    this.resultCount,
    this.createdAt,
  });

  ChatItems.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    topicId = json['topic_id'] ?? json['topicId'];
    userId = json['user_id'] ?? json['userId'];
    prompt = json['prompt'];
    final rawResults = json['results'];
    if (rawResults is String) {
      results = rawResults;
    } else if (rawResults != null) {
      results = jsonEncode(rawResults);
    }
    resultCount = json['result_count'] ?? json['resultCount'];
    createdAt = json['created_at']?.toString() ?? json['createdAt']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['topic_id'] = topicId;
    data['user_id'] = userId;
    data['prompt'] = prompt;
    data['results'] = results;
    data['result_count'] = resultCount;
    data['created_at'] = createdAt;
    return data;
  }

  /// Parses the stored JSON results list into [ArticleData] objects for chat feed display.
  List<ArticleData> get parsedArticles {
    if (results == null || results!.trim().isEmpty) return <ArticleData>[];
    try {
      final decoded = jsonDecode(results!);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((m) => ArticleData.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
    return <ArticleData>[];
  }
}
