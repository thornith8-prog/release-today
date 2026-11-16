import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'article.dart';

/// Represents a single conversational turn in the search results chat feed.
///
/// Each turn consists of:
/// - A user prompt message bubble
/// - An assistant response bubble containing loading state, error state,
///   or list of [ArticleData] results.
class ChatTurn {
  ChatTurn({
    required this.prompt,
    DateTime? timestamp,
    List<ArticleData>? articles,
    bool isLoading = false,
    String? error,
    GlobalKey? promptKey,
    GlobalKey? responseKey,
  })  : timestamp = timestamp ?? DateTime.now(),
        articles = (articles ?? <ArticleData>[]).obs,
        isLoading = isLoading.obs,
        error = RxnString(error),
        promptKey = promptKey ?? GlobalKey(),
        responseKey = responseKey ?? GlobalKey();

  final String prompt;
  final DateTime timestamp;
  final RxList<ArticleData> articles;
  final RxBool isLoading;
  final RxnString error;
  final GlobalKey promptKey;
  /// Key on the assistant message bubble so the page can scroll to the
  /// last assistant turn after results arrive.
  final GlobalKey responseKey;
}
