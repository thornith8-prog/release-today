class Topics {
  int? code;
  String? status;
  String? message;
  Topic? data;

  Topics({this.code, this.status, this.message, this.data});

  Topics.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? Topic.fromJson(json['data']) : null;
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

class Topic {
  int? total;
  List<TopicItems>? items;

  Topic({this.total, this.items});

  Topic.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    if (json['items'] != null) {
      items = <TopicItems>[];
      json['items'].forEach((v) {
        items!.add(TopicItems.fromJson(v));
      });
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

class TopicItems {
  int? id;
  String? name;
  String? userId;
  String? description;
  int? entryCount;
  String? createdAt;
  String? updatedAt;

  TopicItems({
    this.id,
    this.name,
    this.userId,
    this.description,
    this.entryCount,
    this.createdAt,
    this.updatedAt,
  });

  TopicItems.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    userId = json['user_id'];
    description = json['description'];
    entryCount = json['entry_count'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  /// Display title, falling back to a generic label when the name is missing.
  String get label => (name?.trim().isNotEmpty ?? false) ? name!.trim() : 'Topic';

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['user_id'] = userId;
    data['description'] = description;
    data['entry_count'] = entryCount;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}