import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/navigation.dart';

class SearchBarController extends GetxController {
  final textController = TextEditingController();

  /// Active topic ID set when the user selects a topic item from the sidebar,
  /// and cleared when starting a fresh search context (e.g. Home / More).
  final activeTopicId = RxnInt();

  /// Optional listener registered by an active results page.
  /// When present, searches are handled in-place (appending to the chat feed)
  /// rather than triggering route teardown via [AppNav.goSearch].
  void Function(String query)? onSearchSubmitted;

  void setActiveTopic(int? topicId) {
    activeTopicId.value = topicId;
  }

  void clearActiveTopic() {
    activeTopicId.value = null;
  }

  void submit([String? value]) {
    final q = (value ?? textController.text).trim();
    if (q.isEmpty) return;
    textController.clear();
    if (onSearchSubmitted != null) {
      onSearchSubmitted!(q);
    } else {
      AppNav.goSearch(q, topicId: activeTopicId.value);
    }
  }


  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
