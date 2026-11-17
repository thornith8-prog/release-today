import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:newsai/controllers/home_controller.dart';
import 'package:newsai/controllers/more_controller.dart';
import 'package:newsai/data/models/article.dart';
import 'package:newsai/data/repositories/chat_history.dart';
import 'package:newsai/data/repositories/news_repository.dart';
import 'package:newsai/services/api_client.dart';

class FakeNewsRepository extends ApiNewsRepository {
  FakeNewsRepository() : super(ApiClient());

  int callCount = 0;

  @override
  Future<Articles> latest({int skip = 0, int limit = 20}) async {
    callCount++;
    return Articles(data: [ArticleData(id: 1, title: 'Breaking news')]);
  }

  @override
  Future<Articles> search(String query, {int limit = 20, int? topicId}) async =>
      throw UnimplementedError();

  @override
  Future<ChatHistory> getChatByTopicId(int topicId,
          {int skip = 0, int limit = 20}) async =>
      throw UnimplementedError();
}

class FailingNewsRepository extends ApiNewsRepository {
  FailingNewsRepository() : super(ApiClient());

  @override
  Future<Articles> latest({int skip = 0, int limit = 20}) async =>
      throw Exception('downstream timeout');

  @override
  Future<Articles> search(String query, {int limit = 20, int? topicId}) async =>
      throw UnimplementedError();

  @override
  Future<ChatHistory> getChatByTopicId(int topicId,
          {int skip = 0, int limit = 20}) async =>
      throw UnimplementedError();
}

void main() {
  setUp(() {
    Get.reset();
  });

  test('MoreController.load() loads articles and finishes not loading', () async {
    final controller = MoreController(FakeNewsRepository());
    await controller.load();

    expect(controller.articles.length, 1);
    expect(controller.articles.first.title, 'Breaking news');
    expect(controller.isLoading.value, false);
    expect(controller.error.value, null);
  });

  test('MoreController.load() records errors and stops loading', () async {
    final controller = MoreController(FailingNewsRepository());
    await controller.load();

    expect(controller.articles, isEmpty);
    expect(controller.isLoading.value, false);
    expect(controller.error.value, isNotEmpty);
  });

  test('MoreController.load() is a no-op while a fetch is in flight', () async {
    final controller = MoreController(FakeNewsRepository());
    final future1 = controller.load(force: true);
    final future2 = controller.load(force: true);
    await Future.wait([future1, future2]);

    expect(controller.articles.length, 1);
    expect(controller.error.value, null);
  });

  test('MoreController syncs with HomeController when articles already present', () async {
    final repo = FakeNewsRepository();
    final homeController = HomeController(repo);
    homeController.articles.assignAll([
      ArticleData(id: 10, title: 'Home article 1'),
      ArticleData(id: 11, title: 'Home article 2'),
    ]);
    homeController.isLoading.value = false;
    Get.put(homeController);

    final homeCalls = repo.callCount;
    final moreController = MoreController(repo);
    moreController.syncWithHomeController();

    expect(moreController.articles.length, 2);
    expect(moreController.articles.first.title, 'Home article 1');
    expect(moreController.isLoading.value, false);
    expect(repo.callCount, homeCalls); // Seeded without additional network fetch
  });
}
