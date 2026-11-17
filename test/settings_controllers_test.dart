import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:newsai/controllers/about_controller.dart';
import 'package:newsai/controllers/privacy_controller.dart';
import 'package:newsai/controllers/term_controller.dart';
import 'package:newsai/controllers/what_we_do_controller.dart';
import 'package:newsai/data/models/setting.dart';
import 'package:newsai/data/repositories/settings_repository.dart';
import 'package:newsai/services/api_client.dart';
import 'package:newsai/services/isar_service.dart';

class DummyApiClient extends ApiClient {}

void main() {
  late Directory tempDir;
  late IsarService isarService;
  late ApiSettingsRepository repository;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    Get.reset();
    tempDir = await Directory.systemTemp.createTemp('controllers_test_');
    isarService = IsarService();
    await isarService.init(directory: tempDir.path, name: 'ctrl_test_${DateTime.now().millisecondsSinceEpoch}');
    repository = ApiSettingsRepository(DummyApiClient(), isarService);
  });

  tearDown(() async {
    await isarService.close(deleteFromDisk: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Settings Controllers load from Isar', () {
    test('AboutController loads about-us setting from Isar', () async {
      await isarService.putSetting(Setting(
        id: 1,
        slug: 'about-us',
        title: 'About Us from Isar',
        contentHtml: '<p>About Content</p>',
      ));

      final controller = AboutController(repository);
      await controller.loadAbout();

      expect(controller.setting.value, isNotNull);
      expect(controller.setting.value!.slug, 'about-us');
      expect(controller.setting.value!.title, 'About Us from Isar');
      expect(controller.setting.value!.contentHtml, '<p>About Content</p>');
    });

    test('PrivacyController loads privacy setting from Isar', () async {
      await isarService.putSetting(Setting(
        id: 2,
        slug: 'privacy',
        title: 'Privacy from Isar',
        contentHtml: '<p>Privacy Content</p>',
      ));

      final controller = PrivacyController(repository);
      await controller.loadPrivacy();

      expect(controller.setting.value, isNotNull);
      expect(controller.setting.value!.slug, 'privacy');
      expect(controller.setting.value!.title, 'Privacy from Isar');
      expect(controller.setting.value!.contentHtml, '<p>Privacy Content</p>');
    });

    test('WhatWeDoController loads what-we-do setting from Isar', () async {
      await isarService.putSetting(Setting(
        id: 3,
        slug: 'what-we-do',
        title: 'What We Do from Isar',
        contentHtml: '<p>What We Do Content</p>',
      ));

      final controller = WhatWeDoController(repository);
      await controller.loadWhatWeDo();

      expect(controller.setting.value, isNotNull);
      expect(controller.setting.value!.slug, 'what-we-do');
      expect(controller.setting.value!.title, 'What We Do from Isar');
      expect(controller.setting.value!.contentHtml, '<p>What We Do Content</p>');
    });

    test('TermController loads terms setting from Isar', () async {
      await isarService.putSetting(Setting(
        id: 4,
        slug: 'terms',
        title: 'Terms from Isar',
        contentHtml: '<p>Terms Content</p>',
      ));

      final controller = TermController(repository);
      await controller.loadTerms();

      expect(controller.setting.value, isNotNull);
      expect(controller.setting.value!.slug, 'terms');
      expect(controller.setting.value!.title, 'Terms from Isar');
      expect(controller.setting.value!.contentHtml, '<p>Terms Content</p>');
    });
  });
}
