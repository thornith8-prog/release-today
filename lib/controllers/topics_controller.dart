import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/models/topic.dart';
import '../data/repositories/topic_repository.dart';

/// Paginated list of topics belonging to the signed-in user.
///
/// Uses [limit]/[offset] against `GET /search-topic/topics`. The [ApiClient]
/// injects the persisted access token, so only the current user's topics are
/// returned. A 401 triggers an automatic token refresh.
class TopicsController extends GetxController {
  TopicsController(this.repository);

  final TopicRepository repository;

  final topicsItem = <TopicItems>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();

  int _limit = 10;
  int _offset = 0;
  int? _total;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  void onInit() {
    super.onInit();
    load(false);
  }

  /// (Re)load the first page of topics.
  Future<void> load(bool isSearch, {int? limit}) async {
    _limit = limit ?? _limit;
    _offset = 0;
    _hasMore = true;
    isLoading.value = true;
    error.value = null;
    // topicsItem.clear();
    await _fetch(isSearch);
  }

  /// Load the next page of topics. No-op when already loading or no more pages.
  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;
    await _fetch(true);
  }

  Future<void> _fetch(bool isSearch) async {
    try {
      final response = await repository.topics(limit: _limit, offset: _offset);
      final page = response.data?.items ?? <TopicItems>[];
      if (isSearch) {
        topicsItem.assignAll(page);
      } else {
        topicsItem.addAll(page);
      }

      _total = response.data?.total;
      _hasMore = (_offset + page.length) < (_total ?? 0);

      debugPrint(
          'Fetch topics: ${page.length} topics (offset=$_offset, total=$_total)');
    } catch (e, st) {
      debugPrint('Failed to load topics: $e\n$st');
      final msg = e.toString().trim();
      error.value = msg.isEmpty ? 'Failed to load topics.' : msg;
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Deletes a topic by [topicId]. On success, removes it from [topicsItem] in-place.
  Future<bool> deleteTopic(int topicId) async {
    try {
      final success = await repository.deleteTopic(topicId);
      if (success) {
        topicsItem.removeWhere((item) => item.id == topicId);
        if (_total != null && _total! > 0) {
          _total = _total! - 1;
        }
      }
      return success;
    } catch (e) {
      debugPrint('Failed to delete topic $topicId: $e');
      return false;
    }
  }
}
