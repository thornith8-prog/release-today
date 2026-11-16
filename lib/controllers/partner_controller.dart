import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/models/partner.dart';
import '../data/repositories/partner_repository.dart';

/// Loads partners for the home screen (`GET /partners?page=1&limit=50`).
class PartnerController extends GetxController {
  PartnerController(this.repository);

  final PartnerRepository repository;

  final partners = <Items>[].obs;
  final isLoading = true.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load({int page = 1, int limit = 50}) async {
    isLoading.value = true;
    error.value = null;
    try {
      final response = await repository.partners(page: page, limit: limit);
      final rawItems = response.data?.items ?? <Items>[];
      final active = rawItems
          .where((item) => item.isActive != false)
          .toList()
        ..sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));
      debugPrint('Fetch partners: ${active.length} active partners');
      partners.assignAll(active);
    } catch (e) {
      debugPrint('Failed to load partners');
      final msg = e.toString().trim();
      error.value = msg.isEmpty ? 'Failed to load partners.' : msg;
    } finally {
      isLoading.value = false;
    }
  }
}
