import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:newsai/controllers/home_controller.dart';
import 'package:newsai/controllers/more_controller.dart';
import 'package:newsai/data/models/article.dart';
import 'package:newsai/data/repositories/chat_history.dart';
import 'package:newsai/data/repositories/news_repository.dart';
import 'package:newsai/features/more/more_page.dart';
import 'package:newsai/services/api_client.dart';

class FakeNewsRepository extends ApiNewsRepository {
  FakeNewsRepository() : super(ApiClient());

  int callCount = 0;

  @override
  Future<Articles> latest({int skip = 0, int limit = 20}) async {
    callCount++;
    return Articles(data: [ArticleData(id: 1, title: 'Breaking news')]);
  }
}

/// Returns a successful but empty page, simulating a backend with no articles.
class EmptyNewsRepository extends ApiNewsRepository {
  EmptyNewsRepository() : super(ApiClient());

  int callCount = 0;

  @override
  Future<Articles> latest({int skip = 0, int limit = 20}) async {
    callCount++;
    return Articles(data: []);
  }

  @override
  Future<Articles> search(String query, {int limit = 20, int? topicId}) async =>
      throw UnimplementedError();

  @override
  Future<ChatHistory> getChatByTopicId(int topicId,
          {int skip = 0, int limit = 20}) async =>
      throw UnimplementedError();
}

void main() {
  testWidgets('MorePage triggers load() when shown with no articles',
      (tester) async {
    Get.reset();
    final controller = MoreController(FakeNewsRepository());
    Get.put(controller);

    await tester.pumpWidget(const MaterialApp(home: MorePage()));

    // initState schedules load(); the async fetch runs on the microtask queue.
    await tester.pumpAndSettle();

    expect(controller.articles.length, 1);
    expect(controller.articles.first.title, 'Breaking news');
    expect(controller.isLoading.value, false);
    expect(controller.error.value, null);
  });

  testWidgets('MorePage shows a retry when a completed fetch returns no articles',
      (tester) async {
    Get.reset();
    final repo = EmptyNewsRepository();
    final controller = MoreController(repo);
    Get.put(controller);

    await tester.pumpWidget(const MaterialApp(home: MorePage()));
    await tester.pumpAndSettle();

    // initState retried load(); the completed fetch returned no articles.
    expect(controller.articles, isEmpty);
    expect(controller.error.value, isNull);
    expect(controller.isLoading.value, false);
    expect(find.text('Retry'), findsOneWidget);

    // Tapping Retry fetches again instead of leaving the user on EmptyView.
    final beforeRetry = repo.callCount;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(repo.callCount, beforeRetry + 1);
  });

  testWidgets('MorePage does not refetch when articles already loaded',
      (tester) async {
    Get.reset();
    final repo = FakeNewsRepository();
    final controller = MoreController(repo);
    Get.put(controller);
    await controller.load(); // preload, as the permanent controller does at app start

    await tester.pumpWidget(const MaterialApp(home: MorePage()));
    await tester.pumpAndSettle();

    expect(controller.articles.length, 1);
    expect(repo.callCount, 1); // no additional fetch on page show
  });

  testWidgets('MorePage displays articles immediately when HomeController has loaded articles',
      (tester) async {
    Get.reset();
    final repo = FakeNewsRepository();
    final homeController = HomeController(repo);
    homeController.articles.assignAll([
      ArticleData(id: 101, title: 'Headline from home'),
    ]);
    homeController.isLoading.value = false;
    Get.put(homeController);

    final homeCalls = repo.callCount;
    final moreController = MoreController(repo);
    Get.put(moreController);

    await tester.pumpWidget(const MaterialApp(home: MorePage()));
    await tester.pumpAndSettle();

    // Immediately rendered without loading view
    expect(find.text('Headline from home'), findsOneWidget);
    expect(moreController.articles.length, 1);
    expect(repo.callCount, homeCalls); // No extra network call needed
  });
}
