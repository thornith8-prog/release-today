import 'package:get/get.dart';
import 'package:newsai/controllers/term_controller.dart';

import '../controllers/about_controller.dart';
import '../controllers/app_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/more_controller.dart';
import '../controllers/privacy_controller.dart';
import '../controllers/search_bar_controller.dart';
import '../controllers/topics_controller.dart';
import '../controllers/what_we_do_controller.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/news_repository.dart';
import '../data/repositories/partner_repository.dart';
import '../data/models/setting.dart';
import '../data/repositories/topic_entry_repository.dart';
import '../data/repositories/topic_repository.dart';
import '../services/api_client.dart';
import '../services/isar_service.dart';

/// Registers the long-lived dependencies once, when the app starts.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Real backend when NEWS_API_URL is set, otherwise demo data.
    Get.put(ApiClient(), permanent: true);
    Get.put(AuthRepository(Get.find<ApiClient>()), permanent: true);
    final isarService = Get.isRegistered<IsarService>()
        ? Get.find<IsarService>()
        : Get.put(IsarService(), permanent: true);
    final settingsRepo = Get.put(
        ApiNewsRepository(Get.find<ApiClient>(), isarService),
        permanent: true);
    // Sync settings from API to Isar. Fire-and-forget: controllers await
    // repository.syncComplete instead, so the UI never blocks on this call.
    // Errors are swallowed so a failed sync never blocks app startup.
    settingsRepo.syncSettings().catchError((_) => <Setting>[]);
    Get.put(ApiPartnerRepository(Get.find<ApiClient>()), permanent: true);

    Get.put(ApiTopicRepository(Get.find<ApiClient>()), permanent: true);
    Get.put(ApiTopicEntryRepository(Get.find<ApiClient>()), permanent: true);
    Get.put(AppController(Get.find<AuthRepository>()), permanent: true);
    Get.put(SearchBarController(), permanent: true);
    Get.put(HomeController(repository: Get.find<ApiNewsRepository>()),
        permanent: true);
    Get.put(MoreController(Get.find<ApiNewsRepository>()), permanent: true);
    Get.put(TopicsController(Get.find<ApiTopicRepository>()), permanent: true);
    Get.put(
      AboutController(service: isarService, repository: settingsRepo),
      permanent: true,
    );
    Get.put(
      WhatWeDoController(service: isarService, repository: settingsRepo),
      permanent: true,
    );
    Get.put(
      PrivacyController(service: isarService, repository: settingsRepo),
      permanent: true,
    );
    Get.put(
      TermController(service: isarService, repository: settingsRepo),
      permanent: true,
    );
  }
}
