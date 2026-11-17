import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:newsai/data/models/setting.dart';
import 'package:newsai/data/repositories/settings_repository.dart';
import 'package:newsai/services/api_client.dart';
import 'package:newsai/services/isar_service.dart';

class MockApiClient extends ApiClient {
  dynamic responseData;
  int getCallCount = 0;
  String? lastPath;

  MockApiClient({this.responseData});

  @override
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) async {
    getCallCount++;
    lastPath = url;
    return Response<T>(
      statusCode: 200,
      body: responseData as T,
      statusText: 'OK',
    );
  }
}

void main() {
  late Directory tempDir;
  late IsarService isarService;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('settings_repo_test_');
    isarService = IsarService();
    await isarService.init(directory: tempDir.path, name: 'repo_test_${DateTime.now().millisecondsSinceEpoch}');
  });

  tearDown(() async {
    await isarService.close(deleteFromDisk: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SettingsRepository sync and Isar storage', () {
    test('syncSettings inserts settings when local is empty', () async {
      final mockApi = MockApiClient(responseData: {
        'code': 0,
        'status': 'success',
        'data': [
          {
            'id': 1,
            'slug': 'about-us',
            'title': 'About Us',
            'content_html': '<p>About</p>',
            'updated_at': '2026-11-13T12:00:00Z',
          },
          {
            'id': 2,
            'slug': 'privacy',
            'title': 'Privacy Policy',
            'content_html': '<p>Privacy</p>',
            'updated_at': '2026-11-13T12:00:00Z',
          }
        ]
      });

      final repo = ApiSettingsRepository(mockApi, isarService);
      await repo.syncSettings();

      final about = await isarService.getSettingBySlug('about-us');
      final privacy = await isarService.getSettingBySlug('privacy');

      expect(about, isNotNull);
      expect(about!.title, 'About Us');
      expect(privacy, isNotNull);
      expect(privacy!.title, 'Privacy Policy');
    });

    test('syncSettings updates when remote updated_at is newer', () async {
      // Existing local setting
      await isarService.putSetting(Setting(
        id: 1,
        slug: 'terms',
        title: 'Old Terms',
        contentHtml: '<p>Old</p>',
        updatedAt: DateTime.parse('2026-11-13T10:00:00Z'),
      ));

      final mockApi = MockApiClient(responseData: {
        'code': 0,
        'status': 'success',
        'data': [
          {
            'id': 1,
            'slug': 'terms',
            'title': 'New Terms',
            'content_html': '<p>New</p>',
            'updated_at': '2026-11-13T12:00:00Z', // Newer!
          }
        ]
      });

      final repo = ApiSettingsRepository(mockApi, isarService);
      await repo.syncSettings();

      final updated = await isarService.getSettingBySlug('terms');
      expect(updated, isNotNull);
      expect(updated!.title, 'New Terms');
      expect(updated.contentHtml, '<p>New</p>');
    });

    test('syncSettings preserves local setting when remote updated_at is older or equal', () async {
      // Existing newer local setting
      await isarService.putSetting(Setting(
        id: 1,
        slug: 'what-we-do',
        title: 'Local Fresh What We Do',
        contentHtml: '<p>Fresh</p>',
        updatedAt: DateTime.parse('2026-11-13T15:00:00Z'),
      ));

      final mockApi = MockApiClient(responseData: {
        'code': 0,
        'status': 'success',
        'data': [
          {
            'id': 1,
            'slug': 'what-we-do',
            'title': 'Stale Remote What We Do',
            'content_html': '<p>Stale</p>',
            'updated_at': '2026-11-13T12:00:00Z', // Older!
          }
        ]
      });

      final repo = ApiSettingsRepository(mockApi, isarService);
      await repo.syncSettings();

      final current = await isarService.getSettingBySlug('what-we-do');
      expect(current, isNotNull);
      expect(current!.title, 'Local Fresh What We Do');
      expect(current.contentHtml, '<p>Fresh</p>');
    });

    test('getSetting loads directly from Isar if available without network request', () async {
      await isarService.putSetting(Setting(
        id: 1,
        slug: 'about-us',
        title: 'Isar About Us',
        contentHtml: '<p>Loaded from Isar</p>',
      ));

      final mockApi = MockApiClient();
      final repo = ApiSettingsRepository(mockApi, isarService);

      final result = await repo.getSetting('about-us');
      expect(result.title, 'Isar About Us');
      expect(result.contentHtml, '<p>Loaded from Isar</p>');
      expect(mockApi.getCallCount, 0); // No network call needed!
    });
  });
}
