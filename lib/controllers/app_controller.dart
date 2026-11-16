import 'package:get/get.dart';

import '../controllers/search_bar_controller.dart';
import '../controllers/topics_controller.dart';
import '../core/navigation.dart';
import '../core/storage.dart';
import '../data/repositories/auth_repository.dart';
import '../services/api_client.dart';
import '../widgets/contact_us_dialog.dart';

class AppUser {
  const AppUser(
    this.name,
    this.provider, {
    this.userId,
    this.email,
    this.isVerified = true,
  });

  final String name;
  final String provider;
  final String? userId;
  final String? email;
  final bool isVerified;
}

/// App-wide state: recent searches, signed-in user, sidebar visibility.
class AppController extends GetxController {
  AppController([this._authRepository]);

  static const maxRecent = 6;

  final AuthRepository? _authRepository;

  AuthRepository get _auth => _authRepository ?? Get.find<AuthRepository>();

  final recent = <String>[].obs;
  final user = Rxn<AppUser>();
  final sidebarOpen = true.obs;

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  /// Restores the signed-in user and access token from GetStorage so the
  /// session survives an app restart / refresh.
  void _restoreSession() {
    final token = AuthStorage.accessToken;
    if (token != null && token.isNotEmpty) {
      _auth.api.setAuthToken(token);
    }

    final userMap = AuthStorage.user;
    if (userMap != null) {
      final summary = AuthUserSummary.fromJson(userMap);
      user.value = AppUser(
        summary.displayName,
        'email',
        userId: summary.userId,
        email: summary.email,
        isVerified: summary.isVerified,
      );
    }
  }

  void addRecent(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    recent.assignAll([q, ...recent.where((r) => r != q)].take(maxRecent));
  }

  // TODO(security): replace social login stub with OAuth 2.0 / OpenID Connect flow.
  void login(String provider) {
    if (Get.isRegistered<ApiClient>()) {
      Get.find<ApiClient>().setAuthToken(null);
    }
    AuthStorage.clearTokens();
    user.value = AppUser('Thornith', provider);
  }

  /// Registers a new user with email & password and sends a 6-digit OTP to their email.
  Future<AuthActionResult> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.register(email: email, password: password);
  }

  /// Verifies the 6-digit OTP sent to [email].
  /// If [password] is provided, automatically signs the user in after verification.
  Future<AuthActionResult> verifyEmailOtp({
    required String email,
    required String otpCode,
    String? password,
  }) async {
    final result = await _auth.verifyEmail(email: email, otpCode: otpCode);

    if (password != null && password.isNotEmpty) {
      try {
        await loginWithEmail(username: email, password: password);
        return result;
      } catch (_) {
        // Fall back to setting the verified user profile if immediate token login fails.
      }
    }

    final summary = result.user;
    user.value = AppUser(
      summary?.displayName ?? email.split('@').first,
      'email',
      userId: summary?.userId,
      email: summary?.email ?? email,
      isVerified: true,
    );
    if (Get.isRegistered<TopicsController>()) {
      Get.find<TopicsController>().load(false);
    }
    return result;
  }

  /// Requests a fresh 6-digit verification OTP for [email].
  Future<String> resendVerificationOtp({required String email}) {
    return _auth.resendOtp(email: email);
  }

  /// Authenticates with email/username and password.
  Future<AuthTokenResult> loginWithEmail({
    required String username,
    required String password,
  }) async {
    final tokenResult = await _auth.login(
      username: username,
      password: password,
    );
    if (Get.isRegistered<ApiClient>()) {
      Get.find<ApiClient>().setAuthToken(tokenResult.accessToken);
    }

    // Persist the full session so it survives an app restart.
    AuthStorage.saveToken(
      accessToken: tokenResult.accessToken,
      refreshToken: tokenResult.refreshToken,
      tokenType: tokenResult.tokenType,
      expiresInSeconds: tokenResult.expiresIn,
    );
    AuthStorage.saveUser(tokenResult.user.toJson());

    user.value = AppUser(
      tokenResult.user.displayName,
      'email',
      userId: tokenResult.user.userId,
      email: tokenResult.user.email,
      isVerified: tokenResult.user.isVerified,
    );
    if (Get.isRegistered<TopicsController>()) {
      Get.find<TopicsController>().load(false);
    }
    return tokenResult;
  }

  void logout() {
    if (Get.isRegistered<ApiClient>()) {
      Get.find<ApiClient>().setAuthToken(null);
    }
    if (Get.isRegistered<SearchBarController>()) {
      Get.find<SearchBarController>().clearActiveTopic();
    }
    AuthStorage.clear();
    user.value = null;
  }

  /// Opens the Contact Us dialog (email form + Telegram/Facebook/LinkedIn).
  void contactUs() {
    // The app uses go_router, so show the dialog on its root navigator.
    final context = AppNav.router.routerDelegate.navigatorKey.currentContext;
    if (context == null) return;
    showContactUsDialog(context);
  }

  void toggleSidebar() => sidebarOpen.toggle();
}
