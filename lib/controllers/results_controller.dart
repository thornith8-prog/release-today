import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:newsai/data/models/article.dart';
import 'package:newsai/data/models/chat_turn.dart';

import '../data/repositories/chat_history.dart';
import '../data/repositories/news_repository.dart';
import 'articles_controller.dart';
import 'search_bar_controller.dart';

/// Search results for one query and its multi-turn conversation stream.
class ResultsController extends ArticlesController {
  ResultsController({
    required this.query,
    int? topicId,
    required ApiNewsRepository repository,
  })  : currentTopicId = RxnInt(topicId),
        super(repository);

  final String query;

  /// The active topic ID. On fresh searches this starts as null and is populated
  /// as soon as the first search response assigns a new topic, ensuring follow-up
  /// searches append to the same topic rather than creating duplicate topics.
  final RxnInt currentTopicId;

  int? get topicId => currentTopicId.value;
  set topicId(int? value) => currentTopicId.value = value;

  /// Ordered list of chat turns (user prompt + assistant results).
  final turns = <ChatTurn>[].obs;

  @override
  void onInit() {
    // Only pre-seed a turn on fresh searches. For existing topics, turns are
    // populated from getChatByTopicId.
    if (currentTopicId.value == null && query.trim().isNotEmpty) {
      turns.add(ChatTurn(prompt: query, isLoading: true));
    }
    super.onInit();
  }

  @override
  Future<void> load() async {
    // When loaded from an existing topic, load historical chat turns via getChatByTopicId
    // instead of calling repository.search.
    if (currentTopicId.value != null) {
      isLoading.value = true;
      error.value = null;
      try {
        final chatHistory =
            await repository.getChatByTopicId(currentTopicId.value!);
        final rawItems = chatHistory.data?.items ?? <ChatItems>[];
        // Reverse backend response so older chats (yesterday) appear at the top
        // and newer chats (today) appear at the bottom.
        final orderedItems = rawItems.reversed.toList();

        turns.clear();
        final allArticles = <ArticleData>[];
        for (final item in orderedItems) {
          final turnArticles = item.parsedArticles;
          allArticles.addAll(turnArticles);
          DateTime? turnTime;
          if (item.createdAt != null && item.createdAt!.isNotEmpty) {
            turnTime = DateTime.tryParse(item.createdAt!)?.toLocal();
          }
          turns.add(
            ChatTurn(
              prompt: (item.prompt != null && item.prompt!.isNotEmpty)
                  ? item.prompt!
                  : query,
              timestamp: turnTime,
              articles: turnArticles,
              isLoading: false,
            ),
          );
        }

        if (turns.isEmpty && query.trim().isNotEmpty) {
          turns.add(
            ChatTurn(
              prompt: query,
              articles: const [],
              isLoading: false,
            ),
          );
        }

        articles.assignAll(allArticles);
        if (Get.isRegistered<SearchBarController>()) {
          Get.find<SearchBarController>().setActiveTopic(currentTopicId.value);
        }
      } catch (e, st) {
        debugPrint('Failed to load topic history: $e\n$st');
        final msg = e.toString().trim();
        error.value = msg.isEmpty ? 'Failed to load topic history.' : msg;
      } finally {
        isLoading.value = false;
      }
      return;
    }

    await super.load();
    if (turns.isNotEmpty) {
      turns.first.isLoading.value = isLoading.value;
      turns.first.error.value = error.value;
      turns.first.articles.assignAll(articles);
    } else if (query.trim().isNotEmpty) {
      turns.add(
        ChatTurn(
          prompt: query,
          articles: articles,
          isLoading: isLoading.value,
          error: error.value,
        ),
      );
    }
  }

  @override
  Future<Articles> fetch() async {
    if (currentTopicId.value != null) {
      final chatHistory =
          await repository.getChatByTopicId(currentTopicId.value!);
      final rawItems = chatHistory.data?.items ?? <ChatItems>[];
      final orderedItems = rawItems.reversed.toList();
      final allArticles = <ArticleData>[];
      for (final item in orderedItems) {
        allArticles.addAll(item.parsedArticles);
      }
      if (Get.isRegistered<SearchBarController>()) {
        Get.find<SearchBarController>().setActiveTopic(currentTopicId.value);
      }
      return Articles(
        code: chatHistory.code,
        status: chatHistory.status,
        message: chatHistory.message,
        data: allArticles,
        topicId: currentTopicId.value,
      );
    }

    final res = await repository.search(query,
        limit: 20, topicId: currentTopicId.value);
    if (res.topicId != null) {
      currentTopicId.value = res.topicId;
      if (Get.isRegistered<SearchBarController>()) {
        Get.find<SearchBarController>().setActiveTopic(res.topicId);
      }
    }
    return res;
  }

  /// Appends a new user search query and fetches its results in-place without page reload.
  /// Reuses [currentTopicId] so the backend appends to the same topic.
  Future<void> appendSearch(String followUpQuery) async {
    final q = followUpQuery.trim();
    if (q.isEmpty) return;

    final turn = ChatTurn(prompt: q, isLoading: true);
    turns.add(turn);

    try {
      final res =
          await repository.search(q, limit: 20, topicId: currentTopicId.value);
      if (res.topicId != null) {
        currentTopicId.value = res.topicId;
        if (Get.isRegistered<SearchBarController>()) {
          Get.find<SearchBarController>().setActiveTopic(res.topicId);
        }
      }
      final newArticles = res.data ?? <ArticleData>[];
      turn.articles.assignAll(newArticles);
      articles.assignAll(newArticles);
    } catch (e, st) {
      debugPrint('Failed to load search turn: $e\n$st');
      turn.error.value = e.toString().trim();
    } finally {
      turn.isLoading.value = false;
    }
  }

  /// Retries a previously failed turn.
  Future<void> retryTurn(ChatTurn turn) async {
    turn.isLoading.value = true;
    turn.error.value = null;

    try {
      final res = await repository.search(turn.prompt,
          limit: 20, topicId: currentTopicId.value);
      if (res.topicId != null) {
        currentTopicId.value = res.topicId;
        if (Get.isRegistered<SearchBarController>()) {
          Get.find<SearchBarController>().setActiveTopic(res.topicId);
        }
      }
      final newArticles = res.data ?? <ArticleData>[];
      turn.articles.assignAll(newArticles);
    } catch (e, st) {
      debugPrint('Failed to retry turn: $e\n$st');
      turn.error.value = e.toString().trim();
    } finally {
      turn.isLoading.value = false;
    }
  }
}
