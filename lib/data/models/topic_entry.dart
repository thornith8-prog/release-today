import 'dart:convert';

import 'article.dart';

class TopicEntries {
  int? code;
  String? status;
  String? message;
  TopicEntriesData? data;

  TopicEntries({this.code, this.status, this.message, this.data});

  TopicEntries.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    status = json['status'];
    message = json['message'];
    data = json['data'] is Map
        ? TopicEntriesData.fromJson(Map<String, dynamic>.from(json['data']))
        : null;
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

class TopicEntriesData {
  int? topicId;
  String? topicName;
  int? limit;
  int? offset;
  int? total;
  List<TopicEntryItem>? items;
  List<TopicEntry>? entries;

  TopicEntriesData({
    this.topicId,
    this.topicName,
    this.limit,
    this.offset,
    this.total,
    this.items,
    this.entries,
  });

  TopicEntriesData.fromJson(Map<String, dynamic> json) {
    topicId = json['topic_id'] ?? json['topicId'];
    topicName = json['topic_name'] ?? json['topicName'];
    limit = json['limit'];
    offset = json['offset'];
    total = json['total'];

    final parsedEntries = <TopicEntry>[];
    final seenKeys = <String>{};

    void addUniqueEntry(TopicEntry entry) {
      final key = entry.id != null
          ? 'id:${entry.id}'
          : (entry.url != null && entry.url!.isNotEmpty ? 'url:${entry.url}' : null);
      if (key != null && !seenKeys.add(key)) {
        return;
      }
      parsedEntries.add(entry);
    }

    if (json['entries'] is List) {
      for (final v in json['entries']) {
        if (v is Map) {
          addUniqueEntry(TopicEntry.fromJson(Map<String, dynamic>.from(v)));
        }
      }
    }

    if (json['items'] is List) {
      items = <TopicEntryItem>[];
      for (final v in json['items']) {
        if (v is Map) {
          final itemMap = Map<String, dynamic>.from(v);
          final item = TopicEntryItem.fromJson(itemMap);
          items!.add(item);

          if (item.results != null && item.results!.isNotEmpty) {
            for (final article in item.results!) {
              addUniqueEntry(article);
            }
          } else if (itemMap['title'] != null || itemMap['url'] != null) {
            // Fallback when an item in `items` is already an article object.
            addUniqueEntry(TopicEntry.fromJson(itemMap));
          }
        }
      }
    }

    if (items != null && items!.isNotEmpty) {
      topicId ??= items!.first.topicId;
      topicName ??= items!.first.prompt;
    }

    entries = parsedEntries;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['topic_id'] = topicId;
    data['topic_name'] = topicName;
    data['limit'] = limit;
    data['offset'] = offset;
    data['total'] = total;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    if (entries != null) {
      data['entries'] = entries!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

/// A search history entry inside a topic (`GET /search-topic/topics/{id}/entries`).
class TopicEntryItem {
  int? id;
  int? topicId;
  String? userId;
  String? prompt;
  List<TopicEntry>? results;
  int? resultCount;
  String? createdAt;

  TopicEntryItem({
    this.id,
    this.topicId,
    this.userId,
    this.prompt,
    this.results,
    this.resultCount,
    this.createdAt,
  });

  TopicEntryItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    topicId = json['topic_id'] ?? json['topicId'];
    userId = json['user_id'] ?? json['userId'];
    prompt = json['prompt'];
    resultCount = json['result_count'] ?? json['resultCount'];
    createdAt = json['created_at'] ?? json['createdAt'];

    final rawResults = json['results'];
    List<dynamic>? decodedList;
    if (rawResults is List) {
      decodedList = rawResults;
    } else if (rawResults is String && rawResults.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawResults);
        if (decoded is List) {
          decodedList = decoded;
        }
      } catch (_) {
        decodedList = null;
      }
    }

    if (decodedList != null) {
      results = <TopicEntry>[];
      for (final item in decodedList) {
        if (item is Map) {
          results!.add(TopicEntry.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['topic_id'] = topicId;
    data['user_id'] = userId;
    data['prompt'] = prompt;
    if (results != null) {
      data['results'] = results!.map((v) => v.toJson()).toList();
    }
    data['result_count'] = resultCount;
    data['created_at'] = createdAt;
    return data;
  }
}

/// A single news entry belonging to a topic.
class TopicEntry {
  int? id;
  String? source;
  String? url;
  String? title;
  String? summary;
  String? author;
  String? category;
  String? imageUrl;
  String? logoUrl;
  int? clicks;
  int? significanceScore;
  String? publishedAt;
  bool? status;

  TopicEntry({
    this.id,
    this.source,
    this.url,
    this.title,
    this.summary,
    this.author,
    this.category,
    this.imageUrl,
    this.logoUrl,
    this.clicks,
    this.significanceScore,
    this.publishedAt,
    this.status,
  });

  TopicEntry.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    source = json['source'];
    url = json['url'];
    title = json['title'];
    summary = json['summary'];
    author = json['author'];
    category = json['category'];
    imageUrl = json['image_url'] ?? '';
    logoUrl = json['logo_url'];
    clicks = json['clicks'];
    significanceScore = json['significance_score'];
    publishedAt = json['published_at'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['source'] = source;
    data['url'] = url;
    data['title'] = title;
    data['summary'] = summary;
    data['author'] = author;
    data['category'] = category;
    data['image_url'] = imageUrl;
    data['logo_url'] = logoUrl;
    data['clicks'] = clicks;
    data['significance_score'] = significanceScore;
    data['published_at'] = publishedAt;
    data['status'] = status;
    return data;
  }

  /// Returns the published date string, or an empty string when unset.
  String get publishedAtText => publishedAt ?? '';

  /// Converts this [TopicEntry] to an [ArticleData] for unified display in chat turns.
  ArticleData toArticleData() => ArticleData(
        id: id,
        source: source,
        url: url,
        title: title,
        summary: summary,
        author: author,
        category: category,
        imageUrl: imageUrl,
        logoUrl: logoUrl,
        clicks: clicks,
        significanceScore: significanceScore,
        publishedAt: publishedAt,
        status: status,
      );
}
