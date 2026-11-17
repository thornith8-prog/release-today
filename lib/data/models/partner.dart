class Partner {
  int? code;
  String? status;
  String? message;
  PartnerData? data;

  Partner({this.code, this.status, this.message, this.data});

  Partner.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? PartnerData.fromJson(json['data']) : null;
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

class PartnerData {
  int? total;
  int? page;
  int? limit;
  int? totalPages;
  List<PartnerItems>? items;

  PartnerData({this.total, this.page, this.limit, this.totalPages, this.items});

  PartnerData.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    page = json['page'];
    limit = json['limit'];
    totalPages = json['total_pages'];
    if (json['items'] != null) {
      items = <PartnerItems>[];
      json['items'].forEach((v) {
        items!.add(PartnerItems.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total'] = total;
    data['page'] = page;
    data['limit'] = limit;
    data['total_pages'] = totalPages;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PartnerItems {
  int? id;
  String? name;
  String? url;
  String? logoUrl;
  String? description;
  bool? isActive;
  int? displayOrder;
  String? createdAt;
  String? updatedAt;

  PartnerItems(
      {this.id,
      this.name,
      this.url,
      this.logoUrl,
      this.description,
      this.isActive,
      this.displayOrder,
      this.createdAt,
      this.updatedAt});

  PartnerItems.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    url = json['url'];
    logoUrl = json['logo_url'];
    description = json['description'];
    isActive = json['is_active'];
    displayOrder = json['display_order'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['url'] = url;
    data['logo_url'] = logoUrl;
    data['description'] = description;
    data['is_active'] = isActive;
    data['display_order'] = displayOrder;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
