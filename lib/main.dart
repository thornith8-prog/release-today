import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app.dart';
import 'core/env.dart';
import 'services/isar_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Env.load();
  final isarService = IsarService();
  await isarService.init();
  Get.put<IsarService>(isarService, permanent: true);
  runApp(const NewsAiApp());
}
