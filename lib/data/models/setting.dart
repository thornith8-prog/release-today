class Setting {
  final int id;
  final String slug;
  final String title;
  final String contentHtml;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Setting({
    required this.id,
    required this.slug,
    required this.title,
    required this.contentHtml,
    this.createdAt,
    this.updatedAt,
  });

  factory Setting.fromJson(Map<String, dynamic> raw) {
    final Map<String, dynamic> json =
        raw.containsKey('data') && raw['data'] is Map<String, dynamic>
            ? raw['data'] as Map<String, dynamic>
            : raw;

    DateTime? parseDate(dynamic v) {
      if (v == null || v is! String || v.trim().isEmpty) return null;
      return DateTime.tryParse(v);
    }

    return Setting(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      slug: (json['slug'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      contentHtml: (json['content_html'] ?? json['content'] ?? '').toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'title': title,
      'content_html': contentHtml,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
