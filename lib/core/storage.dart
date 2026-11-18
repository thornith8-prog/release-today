import 'package:get_storage/get_storage.dart';

/// Persistent auth storage backed by GetStorage (with an in-memory fallback
/// when platform storage channels are unavailable, such as VM unit tests).
///
/// Holds the access/refresh tokens, token type, expiry, and the signed-in
/// user so the session survives app restarts.
class AuthStorage {
  AuthStorage._();

  static final Map<String, dynamic> _memoryFallback = {};

  static const _accessToken = 'auth.access_token';
  static const _refreshToken = 'auth.refresh_token';
  static const _tokenType = 'auth.token_type';
  static const _expiresAt = 'auth.expires_at';
  static const _user = 'auth.user';

  static dynamic _read(String key) {
    try {
      final val = GetStorage().read(key);
      if (val != null) return val;
    } catch (_) {
      // Fall back to in-memory store when GetStorage is not initialized.
    }
    return _memoryFallback[key];
  }

  static void _write(String key, dynamic value) {
    _memoryFallback[key] = value;
    try {
      GetStorage().write(key, value);
    } catch (_) {
      // Ignore uninitialized storage errors in test environments.
    }
  }

  static void _remove(String key) {
    _memoryFallback.remove(key);
    try {
      GetStorage().remove(key);
    } catch (_) {
      // Ignore uninitialized storage errors in test environments.
    }
  }

  /// Persist a full [AuthTokenResult]-style payload.
  static void saveToken({
    required String accessToken,
    String? refreshToken,
    String? tokenType,
    int? expiresInSeconds,
  }) {
    _write(_accessToken, accessToken);
    if (refreshToken != null) {
      _write(_refreshToken, refreshToken);
    }
    if (tokenType != null) {
      _write(_tokenType, tokenType);
    }
    if (expiresInSeconds != null && expiresInSeconds > 0) {
      _write(
        _expiresAt,
        DateTime.now()
            .add(Duration(seconds: expiresInSeconds))
            .toIso8601String(),
      );
    }
  }

  static String? get accessToken => _read(_accessToken)?.toString();
  static String? get refreshToken => _read(_refreshToken)?.toString();
  static String? get tokenType => _read(_tokenType)?.toString();

  static DateTime? get expiresAt {
    final raw = _read(_expiresAt);
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  /// True when the access token is missing or expires within the next 60s.
  static bool get isAccessTokenExpired {
    final at = expiresAt;
    if (at == null) return true;
    return at.isBefore(DateTime.now().add(const Duration(seconds: 60)));
  }

  static void saveUser(Map<String, dynamic> user) {
    _write(_user, Map<String, dynamic>.from(user));
  }

  static Map<String, dynamic>? get user {
    final raw = _read(_user);
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  /// Clears only the persisted tokens while preserving the user profile.
  static void clearTokens() {
    _remove(_accessToken);
    _remove(_refreshToken);
    _remove(_tokenType);
    _remove(_expiresAt);
  }

  /// Wipe every persisted auth value.
  static void clear() {
    clearTokens();
    _remove(_user);
  }
}
