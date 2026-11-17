import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads settings from the bundled `.env` asset. `--dart-define=NEWS_API_URL=...`
/// is used as a fallback (handy on hosts that do not serve dotfiles).
class Env {
  Env._();

  static const _definedUrl = String.fromEnvironment(
    'NEWS_API_URL',
    defaultValue: 'https://news-ai-d115c798.fastapicloud.dev',
  );

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // No .env bundled: fall back to defaults / --dart-define.
    }
  }

  static String _get(String key, String fallback) {
    final value = dotenv.isInitialized ? dotenv.maybeGet(key) : null;
    return (value == null || value.isEmpty) ? fallback : value;
  }

  static String get apiUrl {
    final raw = _get('NEWS_API_URL', _definedUrl);
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  /// Origin for public article share links (`{shareBaseUrl}/s/{id}`).
  /// Defaults to the API host, which serves the share page.
  static String get shareBaseUrl {
    final raw = _get('SHARE_BASE_URL', apiUrl);
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static String get latestPath => _get('NEWS_API_LATEST_PATH', '/recommendations/');
  static String get partnersPath => _get('NEWS_API_PARTNERS_PATH', '/partners');
  static String get searchPath => _get('NEWS_API_SEARCH_PATH', '/search/');
  static String get chatHistory => _get('NEWS_API_CHAT_HISTORY_PATH', '/search-topic/topics/');
  static String get searchParam => _get('NEWS_API_SEARCH_PARAM', 'q');
  static String get registerPath => _get('NEWS_API_REGISTER_PATH', '/auth/register');
  static String get verifyEmailPath => _get('NEWS_API_VERIFY_EMAIL_PATH', '/auth/verify-email');
  static String get resendOtpPath => _get('NEWS_API_RESEND_OTP_PATH', '/auth/resend-otp');
  static String get loginPath => _get('NEWS_API_LOGIN_PATH', '/auth/login');
  static String get refreshPath => _get('NEWS_API_REFRESH_PATH', '/auth/refresh');
  static String get topicsPath => _get('NEWS_API_TOPICS_PATH', '/search-topic/topics');
  static String get settingsPath => _get('NEWS_API_SETTINGS_PATH', '/settings');
  // Contact Us dialog. Override these in `.env` with your real accounts.
  static String get contactEmail => _get('CONTACT_EMAIL', 'support@newsai.app');
  static String get telegramUrl => _get('CONTACT_TELEGRAM_URL', 'https://t.me/newsai');
  static String get facebookUrl => _get('CONTACT_FACEBOOK_URL', 'https://www.facebook.com/newsai');
  static String get linkedinUrl => _get('CONTACT_LINKEDIN_URL', 'https://www.linkedin.com/company/newsai');

  /// Legal / info pages opened from the sidebar. Override these in `.env`
  /// with your real pages.
  static String get aboutUrl => _get('ABOUT_URL', 'https://newsai.app/about');
  static String get whatWeDoUrl =>
      _get('WHAT_WE_DO_URL', 'https://newsai.app/what-we-do');
  static String get termsUrl => _get('TERMS_URL', 'https://newsai.app/terms');
  static String get privacyUrl =>
      _get('PRIVACY_URL', 'https://newsai.app/privacy');

  static bool get useCorsProxy => _get('NEWS_API_USE_CORS_PROXY', 'false').toLowerCase() == 'true';
  static int get timeoutSeconds => int.tryParse(_get('NEWS_API_TIMEOUT', '30')) ?? 30;
}
