import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:newsai/data/models/setting.dart';
import 'package:newsai/services/isar_service.dart';

void main() {
  late Directory tempDir;
  late IsarService isarService;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('isar_test_');
    isarService = IsarService();
    await isarService.init(directory: tempDir.path, name: 'test_${DateTime.now().millisecondsSinceEpoch}');
  });

  tearDown(() async {
    await isarService.close(deleteFromDisk: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('IsarService tests', () {
    test('putSetting and getSettingBySlug retrieves correct setting', () async {
      final setting = Setting(
        id: 1,
        slug: 'about-us',
        title: 'About Us',
        contentHtml: '<h1>About Us</h1>',
        updatedAt: DateTime.parse('2026-11-13T12:00:00Z'),
      );

      await isarService.putSetting(setting);
      final retrieved = await isarService.getSettingBySlug('about-us');

      expect(retrieved, isNotNull);
      expect(retrieved!.slug, 'about-us');
      expect(retrieved.title, 'About Us');
      expect(retrieved.contentHtml, '<h1>About Us</h1>');
    });

    test('putAllSettings and getAllSettings retrieves all items', () async {
      final s1 = Setting(id: 1, slug: 'about-us', title: 'About Us', contentHtml: 'About');
      final s2 = Setting(id: 2, slug: 'privacy', title: 'Privacy Policy', contentHtml: 'Privacy');

      await isarService.putAllSettings([s1, s2]);
      final all = await isarService.getAllSettings();

      expect(all.length, 2);
      expect(all.map((s) => s.slug).toSet(), containsAll({'about-us', 'privacy'}));
    });

    test('getSettingBySlug returns null for nonexistent slug', () async {
      final retrieved = await isarService.getSettingBySlug('nonexistent');
      expect(retrieved, isNull);
    });
  });
}
