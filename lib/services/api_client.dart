import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import 'package:newsai/controllers/app_controller.dart';
import 'package:newsai/core/env.dart';
import 'package:newsai/core/storage.dart';

class ApiClient extends GetConnect {
  ApiClient({Uri? pageOrigin}) : _pageOrigin = pageOrigin;

  final Uri? _pageOrigin;

  bool _preferLocalProxy = false;
  String? _authToken;
  bool _isRefreshing = false;

  /// True when running in a browser served from `localhost` or `127.0.0.1`.
  /// Ensures a deployed build on a public domain never attempts to call
  /// `127.0.0.1:8787` even if `.env` had `NEWS_API_USE_CORS_PROXY=true`.
  bool get _isLocalBrowserOrigin {
    final origin = _pageOrigin ?? Uri.base;
    return (origin.scheme == 'http' || origin.scheme == 'https') &&
        (origin.host == 'localhost' || origin.host == '127.0.0.1');
  }

  bool get _corsProxyEnabled => Env.useCorsProxy && _isLocalBrowserOrigin;

  /// Stores the bearer token in memory (not in browser localStorage).
  void setAuthToken(String? token) {
    _authToken = (token != null && token.isNotEmpty) ? token : null;
  }

  bool _isPublicAuthEndpoint(Uri url) {
    final path = url.path;
    return path.endsWith(Env.refreshPath) ||
        path.endsWith(Env.loginPath) ||
        path.endsWith(Env.registerPath) ||
        path.endsWith(Env.verifyEmailPath) ||
        path.endsWith(Env.resendOtpPath);
  }

  String? _currentUserId() {
    if (Get.isRegistered<AppController>()) {
      final uid = Get.find<AppController>().user.value?.userId;
      if (uid != null && uid.isNotEmpty) return uid;
    }
    final storedUser = AuthStorage.user;
    final storedUid = storedUser?['user_id']?.toString();
    if (storedUid != null && storedUid.isNotEmpty) return storedUid;
    return null;
  }

  void _applyRequestModifiers(dynamic request) {
    if (request.method.toLowerCase() == 'get') {
      request.headers.remove('content-type');
      request.headers.remove('Content-Type');
    }
    if (_isPublicAuthEndpoint(request.url)) {
      request.headers.remove('Authorization');
      request.headers.remove('authorization');
      return;
    }
    if (_authToken != null && _authToken!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    } else {
      request.headers.remove('Authorization');
      request.headers.remove('authorization');
    }
    final userId = _currentUserId();
    if (userId != null) {
      request.headers['X-User-Id'] = userId;
    }
  }

  late final GetHttpClient _proxyClient = GetHttpClient(
    baseUrl: Env.corsProxyUrl,
    timeout: Duration(seconds: Env.timeoutSeconds),
  )
    ..defaultContentType = 'application/json'
    ..addRequestModifier<dynamic>((request) async {
      _applyRequestModifiers(request);
      return request;
    });

  @override
  void onInit() {
    super.onInit();

    baseUrl = Env.apiUrl;
    timeout = Duration(seconds: Env.timeoutSeconds);
    httpClient.baseUrl = Env.apiUrl;
    httpClient.timeout = Duration(seconds: Env.timeoutSeconds);
    httpClient.defaultContentType = 'application/json';

    // When running locally in Chrome with NEWS_API_USE_CORS_PROXY=true, send
    // requests through the local proxy immediately instead of waiting for a
    // slow CORS-blocked roundtrip to fail first.
    _preferLocalProxy = _corsProxyEnabled;

    // Restore the persisted access token so the session survives a refresh.
    _authToken = AuthStorage.accessToken;

    // Request modifier: inject auth headers, skip Content-Type on GET to avoid
    // unnecessary CORS preflight OPTIONS requests.
    httpClient.addRequestModifier<dynamic>((request) async {
      _applyRequestModifiers(request);
      return request;
    });
  }

  /// Dispatches one HTTP call, preferring the local CORS proxy when running on
  /// localhost with `NEWS_API_USE_CORS_PROXY=true`, and falling back between
  /// proxy and direct transport if one is unreachable.
  Future<Response<T>> _dispatch<T>({
    required Future<Response<T>> Function() directCall,
    required Future<Response<T>> Function() proxyCall,
  }) async {
    if (!_corsProxyEnabled) {
      return directCall();
    }

    if (_preferLocalProxy) {
      try {
        final proxyRes = await proxyCall();
        if (proxyRes.statusCode != null) {
          return proxyRes;
        }
      } catch (_) {
        // Proxy unreachable; try direct request in case backend CORS allows localhost.
      }

      final directRes = await directCall();
      if (directRes.statusCode != null) {
        _preferLocalProxy = false;
        return directRes;
      }

      throw 'The local CORS proxy at ${Env.corsProxyUrl} is not running. '
          'Start it with `dart run tool/cors_proxy.dart` (or ./run_web.sh), '
          'then reload the page.';
    }

    final directRes = await directCall();
    if (directRes.statusCode != null) {
      return directRes;
    }

    try {
      final proxyRes = await proxyCall();
      if (proxyRes.statusCode != null) {
        _preferLocalProxy = true;
        return proxyRes;
      }
    } catch (_) {
      // Proxy unreachable.
    }

    throw 'The local CORS proxy at ${Env.corsProxyUrl} is not running. '
        'Start it with `dart run tool/cors_proxy.dart` (or ./run_web.sh), '
        'then reload the page.';
  }

  /// POST /auth/refresh. Returns true when a new access token was obtained.
  Future<bool> _refreshAccessToken() async {
    final refreshToken = AuthStorage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    if (_isRefreshing) {
      while (_isRefreshing) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return _authToken != null && _authToken!.isNotEmpty;
    }

    _isRefreshing = true;
    try {
      final payload = {'refresh_token': refreshToken};
      final response = await _dispatch<dynamic>(
        directCall: () => super.post(Env.refreshPath, payload),
        proxyCall: () => _proxyClient.post(Env.refreshPath, body: payload),
      );

      if (response.statusCode == null || response.status.hasError) {
        return false;
      }

      final body = response.body;
      Map<String, dynamic> json;
      if (body is Map<String, dynamic>) {
        json = body;
      } else if (body is Map) {
        json = Map<String, dynamic>.from(body);
      } else if (body is String && body.trim().isNotEmpty) {
        try {
          json = jsonDecode(body) as Map<String, dynamic>;
        } catch (_) {
          return false;
        }
      } else {
        return false;
      }

      final dataMap = (json['data'] is Map)
          ? Map<String, dynamic>.from(json['data'])
          : json;
      final newAccessToken =
          (dataMap['access_token'] ?? json['access_token'] ?? '').toString();
      final newRefreshToken =
          (dataMap['refresh_token'] ?? refreshToken).toString();
      final newExpiresIn = dataMap['expiresIn'] ??
          dataMap['expires_in'] ??
          json['expiresIn'] ??
          json['expires_in'];

      if (newAccessToken.isEmpty) {
        return false;
      }

      final expiresIn = newExpiresIn is int
          ? newExpiresIn
          : int.tryParse(newExpiresIn.toString()) ?? 300;

      _authToken = newAccessToken;
      AuthStorage.saveToken(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken.isNotEmpty ? newRefreshToken : null,
        expiresInSeconds: expiresIn,
      );

      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Clears expired/invalid tokens in memory and storage without logging out
  /// the user or redirecting away from the current page.
  void _clearExpiredToken() {
    _authToken = null;
    AuthStorage.clearTokens();
  }

  Future<void> _ensureFreshTokenIfNeeded(String? url) async {
    if (url != null && _isPublicAuthEndpoint(Uri.parse(url))) {
      return;
    }
    if (_authToken != null &&
        AuthStorage.expiresAt != null &&
        AuthStorage.isAccessTokenExpired) {
      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        _clearExpiredToken();
      }
    }
  }

  Future<Response<T>> _withAuthRetry<T>(
    String? url,
    Future<Response<T>> Function() execute,
  ) async {
    await _ensureFreshTokenIfNeeded(url);
    final hadToken = _authToken != null && _authToken!.isNotEmpty;

    final response = await execute();

    if (response.statusCode == 401 &&
        (url == null || !_isPublicAuthEndpoint(Uri.parse(url)))) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return execute();
      }
      if (hadToken) {
        _clearExpiredToken();
        return execute();
      }
    }

    return response;
  }

  @override
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) {
    return _withAuthRetry<T>(
      url,
      () => _dispatch<T>(
        directCall: () => super.get<T>(
          url,
          headers: headers,
          contentType: contentType,
          query: query,
          decoder: decoder,
        ),
        proxyCall: () => _proxyClient.get<T>(
          url,
          headers: headers,
          contentType: contentType,
          query: query,
          decoder: decoder,
        ),
      ),
    );
  }

  @override
  Future<Response<T>> post<T>(
    String? url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    return _withAuthRetry<T>(
      url,
      () => _dispatch<T>(
        directCall: () => super.post<T>(
          url,
          body,
          contentType: contentType,
          headers: headers,
          query: query,
          decoder: decoder,
          uploadProgress: uploadProgress,
        ),
        proxyCall: () => _proxyClient.post<T>(
          url,
          body: body,
          contentType: contentType,
          headers: headers,
          query: query,
          decoder: decoder,
          uploadProgress: uploadProgress,
        ),
      ),
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) {
    return _withAuthRetry<T>(
      url,
      () => _dispatch<T>(
        directCall: () => super.delete<T>(
          url,
          headers: headers,
          contentType: contentType,
          query: query,
          decoder: decoder,
        ),
        proxyCall: () => _proxyClient.delete<T>(
          url,
          headers: headers,
          contentType: contentType,
          query: query,
          decoder: decoder,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _proxyClient.close();
    super.dispose();
  }
}
