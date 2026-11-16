import 'package:newsai/data/repositories/chat_history.dart';

import '../models/article.dart';

abstract class NewsRepository {
  Future<Articles> latest({int skip = 0, int limit = 20});

  Future<Articles> search(String query, {int limit = 20, int? topicId});

  Future<ChatHistory> getChatByTopicId(int topicId,
      {int skip = 0, int limit = 20});
}
