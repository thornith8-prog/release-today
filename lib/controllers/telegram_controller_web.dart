import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';

/// Controller for the Telegram Mini App support screen (Web implementation).
class TelegramController extends GetxController {
  TelegramController();

  final WebApp _app = WebApp();

  /// Whether the app is running inside Telegram.
  final RxBool isInTelegram = false.obs;

  /// Whether [init] has run at least once.
  final RxBool isInitialized = false.obs;

  /// Capture any initialization error so the surface can render it.
  final RxnString error = RxnString();

  /// The Bot API version available in the user's Telegram app.
  String? get version => isInTelegram.value ? _app.version : null;

  /// The platform of the user's Telegram app.
  String? get platform => isInTelegram.value ? _app.platform : null;

  /// The current Telegram color scheme ("light" or "dark").
  String? get colorScheme =>
      isInTelegram.value ? _app.colorScheme.name : null;

  /// Raw init data string (validate on the bot server before trusting).
  String? get initData => isInTelegram.value ? _app.initData : null;

  /// The Telegram user's first name (untrusted client data).
  String? get userFirstName =>
      isInTelegram.value ? _app.initDataUnsafe.user?.firstName : null;

  /// The Telegram user's last name (untrusted client data).
  String? get userLastName =>
      isInTelegram.value ? _app.initDataUnsafe.user?.lastName : null;

  /// The Telegram user's username (untrusted client data).
  String? get userUsername =>
      isInTelegram.value ? _app.initDataUnsafe.user?.username : null;

  /// The Telegram user's profile photo URL (untrusted client data).
  String? get userPhotoUrl =>
      isInTelegram.value ? _app.initDataUnsafe.user?.photoUrl : null;

  /// Whether the Telegram user is a Telegram Premium subscriber.
  bool get userIsPremium =>
      isInTelegram.value ? _app.initDataUnsafe.user?.isPremium ?? false : false;

  /// Whether the Mini App is expanded to maximum height.
  bool get isExpanded => isInTelegram.value ? _app.isExpanded : false;

  /// Current height of the visible Mini App area.
  double get viewportHeight =>
      isInTelegram.value ? _app.viewportHeight : 0.0;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  /// Initialize the Mini App. Safe to call outside Telegram.
  Future<void> init() async {
    if (isInitialized.value) return;
    try {
      final supported = _app.isSupported;
      isInTelegram.value = supported;
      if (supported) {
        _app.init();
        _app.ready();
        _app.expand();
      }
      error.value = null;
    } catch (_) {
      // Avoid logging raw error payloads that could contain initData tokens.
      debugPrint('Telegram Mini App initialization failed.');
      error.value = 'Unable to initialize Telegram Mini App.';
    } finally {
      isInitialized.value = true;
    }
  }

  /// Closes the Mini App.
  void close() {
    if (!isInTelegram.value) return;
    _app.close();
  }

  /// Opens [url] in an external browser from within the Mini App.
  void openLink({required String url}) {
    if (!isInTelegram.value) return;
    _app.openLink(url: url);
  }

  /// Shows or hides the Telegram main button.
  void setMainButtonVisible(bool visible) {
    if (!isInTelegram.value) return;
    visible ? _app.mainButton.show() : _app.mainButton.hide();
  }

  /// Sets the main button text.
  void setMainButtonText(String text) {
    if (!isInTelegram.value) return;
    _app.mainButton.setText(text);
  }

  /// Shows or hides the Telegram back button.
  void setBackButtonVisible(bool visible) {
    if (!isInTelegram.value) return;
    visible ? _app.backButton.show() : _app.backButton.hide();
  }

  /// Shows a Telegram alert dialog.
  void showAlert({required String message}) {
    if (!isInTelegram.value) return;
    _app.showAlert(message: message);
  }

  /// Shows a Telegram confirmation dialog and returns whether the user pressed OK.
  Future<bool> showConfirm({required String message}) async {
    if (!isInTelegram.value) return false;
    return _app.showConfirmAsync(message: message);
  }
}
