import 'package:get_storage/get_storage.dart';

/// Persistent auth storage backed by GetStorage.
///
/// Holds the access/refresh tokens, token type, expiry, and the signed-in
/// user so the session survives app restarts.
class AuthStorage {
  AuthStorage._();

  static final _box = GetStorage();

  static const _accessToken = 'auth.access_token';
  static const _refreshToken = 'auth.refresh_token';
  static const _tokenType = 'auth.token_type';
  static const _expiresAt = 'auth.expires_at';
  static const _user = 'auth.user';

  /// Persist a full [AuthTokenResult]-style payload.
  static void saveToken({
    required String accessToken,
    String? refreshToken,
    String? tokenType,
    int? expiresInSeconds,
  }) {
    _box.write(_accessToken, accessToken);
    if (refreshToken != null) {
      _box.write(_refreshToken, refreshToken);
    }
    if (tokenType != null) {
      _box.write(_tokenType, tokenType);
    }
    if (expiresInSeconds != null && expiresInSeconds > 0) {
      _box.write(
        _expiresAt,
        DateTime.now().add(Duration(seconds: expiresInSeconds)).toIso8601String(),
      );
    }
  }

  static String? get accessToken => _box.read(_accessToken);
  static String? get refreshToken => _box.read(_refreshToken);
  static String? get tokenType => _box.read(_tokenType);

  static DateTime? get expiresAt {
    final raw = _box.read(_expiresAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// True when the access token is missing or expires within the next 60s.
  static bool get isAccessTokenExpired {
    final at = expiresAt;
    if (at == null) return true;
    return at.isBefore(DateTime.now().add(const Duration(seconds: 60)));
  }

  static void saveUser(Map<String, dynamic> user) {
    _box.write(_user, user);
  }

  static Map<String, dynamic>? get user => _box.read(_user);

  /// Clears only the persisted tokens while preserving the user profile.
  static void clearTokens() {
    _box.remove(_accessToken);
    _box.remove(_refreshToken);
    _box.remove(_tokenType);
    _box.remove(_expiresAt);
  }

  /// Wipe every persisted auth value.
  static void clear() {
    clearTokens();
    _box.remove(_user);
  }
}
