class Articles {
  int? code;
  String? status;
  String? message;
  List<ArticleData>? data;
  int? topicId;

  Articles({this.code, this.status, this.message, this.data, this.topicId});

  Articles.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    status = json['status'];
    message = json['message'];
    final rawTopicId = json['topicId'] ?? json['topic_id'];
    if (rawTopicId is int) {
      topicId = rawTopicId;
    } else if (rawTopicId != null) {
      topicId = int.tryParse(rawTopicId.toString());
    }
    if (json['data'] != null) {
      data = <ArticleData>[];
      json['data'].forEach((v) {
        data!.add(ArticleData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['status'] = status;
    data['message'] = message;
    if (topicId != null) {
      data['topicId'] = topicId;
    }
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ArticleData {
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

  /// Returns the published date string, or an empty string when unset.
  String get publishedAtText => publishedAt ?? '';

  ArticleData(
      {this.id,
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
      this.status});

  ArticleData.fromJson(Map<String, dynamic> json) {
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
}
