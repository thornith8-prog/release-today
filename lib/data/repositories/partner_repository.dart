import 'dart:convert';

import 'package:get/get.dart';

import '../../core/env.dart';
import '../../services/api_client.dart';
import '../models/partner.dart';

class PartnerApiException implements Exception {
  PartnerApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class PartnerRepository {
  Future<Partner> partners({int page = 1, int limit = 50});
}

/// Backed by `GET /partners?page=1&limit=50`.
class ApiPartnerRepository implements PartnerRepository {
  final ApiClient api;
  ApiPartnerRepository(this.api);

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
    final Map<String, dynamic> json = switch (raw) {
      Map<String, dynamic> m => m,
      Map m => Map<String, dynamic>.from(m),
      String s => jsonDecode(s) as Map<String, dynamic>,
      _ => throw PartnerApiException(
          'Unexpected response format: ${raw.runtimeType}'),
    };
    return Partner.fromJson(json);
  }

  @override
  Future<Partner> partners({int page = 1, int limit = 50}) async {
    final response = await api.get(
      Env.partnersPath,
      query: {'page': '$page', 'limit': '$limit'},
    );
    return _parsePartners(response);
  }
}
