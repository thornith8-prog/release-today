import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/models/article.dart';
import '../data/models/chat_turn.dart';
import '../data/models/topic_entry.dart';
import '../data/repositories/news_repository.dart';
import '../data/repositories/topic_entry_repository.dart';

/// Paginated list of entries for a single topic and its multi-turn conversation stream.
class TopicEntryController extends GetxController {
  TopicEntryController(this.repository, {required this.topicId});

  final TopicEntryRepository repository;
  final int topicId;

  final entries = <TopicEntry>[].obs;
  final turns = <ChatTurn>[].obs;
  final topicPrompt = RxnString();
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
    load();
  }

  /// (Re)load the first page of entries for [topicId].
  Future<void> load({int? limit}) async {
    _limit = limit ?? _limit;
    _offset = 0;
    _hasMore = true;
    isLoading.value = true;
    error.value = null;
    entries.clear();
    turns.clear();
    await _fetch();
  }

  /// Load the next page of entries. No-op when already loading or no more pages.
  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final isInitialLoad = _offset == 0;
      final response = await repository.entries(
        topicId: topicId,
        limit: _limit,
        offset: _offset,
      );

      // Reverse data after response so previous data is kept at the top
      // and current data is kept at the bottom like chat history.
      if (response.data?.entries != null) {
        response.data!.entries = response.data!.entries!.reversed.toList();
      }
      if (response.data?.items != null) {
        response.data!.items = response.data!.items!.reversed.toList();
      }

      final page = response.data?.entries ?? <TopicEntry>[];
      final existingKeys = entries
          .map((e) => e.id != null ? 'id:${e.id}' : (e.url != null ? 'url:${e.url}' : null))
          .whereType<String>()
          .toSet();
      final newEntries = <TopicEntry>[];
      for (final entry in page) {
        final key = entry.id != null
            ? 'id:${entry.id}'
            : (entry.url != null && entry.url!.isNotEmpty ? 'url:${entry.url}' : null);
        if (key == null || existingKeys.add(key)) {
          newEntries.add(entry);
        }
      }
      if (isInitialLoad) {
        entries.addAll(newEntries);
      } else {
        entries.insertAll(0, newEntries);
      }

      final name = response.data?.topicName?.trim();
      if (name != null && name.isNotEmpty) {
        topicPrompt.value = name;
      }

      // Populate conversation turns from historical items
      final items = response.data?.items ?? <TopicEntryItem>[];
      final newTurns = <ChatTurn>[];
      if (items.isNotEmpty) {
        for (final item in items) {
          DateTime? turnTime;
          if (item.createdAt != null && item.createdAt!.isNotEmpty) {
            turnTime = DateTime.tryParse(item.createdAt!)?.toLocal();
          }
          final turnArticles =
              (item.results ?? <TopicEntry>[]).map((e) => e.toArticleData()).toList();
          newTurns.add(
            ChatTurn(
              prompt: (item.prompt != null && item.prompt!.isNotEmpty)
                  ? item.prompt!
                  : (topicPrompt.value ?? 'Topic'),
              timestamp: turnTime,
              articles: turnArticles,
              isLoading: false,
            ),
          );
        }
      } else if (turns.isEmpty && page.isNotEmpty) {
        newTurns.add(
          ChatTurn(
            prompt: topicPrompt.value ?? 'Topic',
            articles: page.map((e) => e.toArticleData()).toList(),
            isLoading: false,
          ),
        );
      }

      if (isInitialLoad) {
        turns.addAll(newTurns);
      } else {
        turns.insertAll(0, newTurns);
      }

      final fetchedItemsCount = response.data?.items?.length ?? page.length;
      _offset = (response.data?.offset ?? _offset) + fetchedItemsCount;
      _total = response.data?.total;
      _hasMore = fetchedItemsCount > 0 && _offset < (_total ?? 0);

      debugPrint(
        'Fetch topic entries: ${page.length} articles from $fetchedItemsCount items '
        '(topicId=$topicId, offset=$_offset, total=$_total)',
      );
    } catch (e, st) {
      debugPrint('Failed to load topic entries: $e\n$st');
      final msg = e.toString().trim();
      error.value = msg.isEmpty ? 'Failed to load topic entries.' : msg;
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Appends a new user search query to this topic without reloading the page.
  Future<void> appendSearch(String followUpQuery, {ApiNewsRepository? newsRepo}) async {
    final q = followUpQuery.trim();
    if (q.isEmpty) return;

    final repo = newsRepo ??
        (Get.isRegistered<ApiNewsRepository>() ? Get.find<ApiNewsRepository>() : null);
    if (repo == null) {
      debugPrint('ApiNewsRepository not found to append search in TopicEntryController');
      return;
    }

    final turn = ChatTurn(prompt: q, isLoading: true);
    turns.add(turn);

    try {
      final res = await repo.search(q, limit: 20, topicId: topicId);
      final newArticles = res.data ?? <ArticleData>[];
      turn.articles.assignAll(newArticles);
    } catch (e, st) {
      debugPrint('Failed to append search in topic: $e\n$st');
      turn.error.value = e.toString().trim();
    } finally {
      turn.isLoading.value = false;
    }
  }

  /// Retries a previously failed turn.
  Future<void> retryTurn(ChatTurn turn, {ApiNewsRepository? newsRepo}) async {
    final repo = newsRepo ??
        (Get.isRegistered<ApiNewsRepository>() ? Get.find<ApiNewsRepository>() : null);
    if (repo == null) return;

    turn.isLoading.value = true;
    turn.error.value = null;

    try {
      final res = await repo.search(turn.prompt, limit: 20, topicId: topicId);
      final newArticles = res.data ?? <ArticleData>[];
      turn.articles.assignAll(newArticles);
    } catch (e, st) {
      debugPrint('Failed to retry turn in topic: $e\n$st');
      turn.error.value = e.toString().trim();
    } finally {
      turn.isLoading.value = false;
    }
  }
}
