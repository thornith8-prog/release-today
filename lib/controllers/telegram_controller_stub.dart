import 'package:get/get.dart';

/// Non-web stub for [TelegramController] so non-web platforms and VM widget
/// tests compile cleanly without `dart:js_interop`.
class TelegramController extends GetxController {
  TelegramController();

  final RxBool isInTelegram = false.obs;
  final RxBool isInitialized = false.obs;
  final RxnString error = RxnString();

  String? get version => null;
  String? get platform => null;
  String? get colorScheme => null;
  String? get initData => null;
  String? get userFirstName => null;
  String? get userLastName => null;
  String? get userUsername => null;
  String? get userPhotoUrl => null;
  bool get userIsPremium => false;
  bool get isExpanded => false;
  double get viewportHeight => 0.0;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    if (isInitialized.value) return;
    isInTelegram.value = false;
    isInitialized.value = true;
    error.value = null;
  }

  void close() {}
  void openLink({required String url}) {}
  void setMainButtonVisible(bool visible) {}
  void setMainButtonText(String text) {}
  void setBackButtonVisible(bool visible) {}
  void showAlert({required String message}) {}
  Future<bool> showConfirm({required String message}) async => false;
}
