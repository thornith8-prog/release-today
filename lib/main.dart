import 'package:flutter/widgets.dart';
import 'package:get_storage/get_storage.dart';

import 'app.dart';
import 'core/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Env.load();
  runApp(const NewsAiApp());
}
