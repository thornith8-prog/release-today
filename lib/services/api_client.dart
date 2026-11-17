import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:newsai/core/env.dart';
import 'package:newsai/core/storage.dart';
import 'package:newsai/controllers/app_controller.dart';

class ApiClient extends GetConnect {
  static const String _localCorsProxy = 'http://127.0.0.1:8787';

  bool _useWebCorsProxy = false;
  String? _authToken;
  bool _isRefreshing = false;

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
    baseUrl: _localCorsProxy,
    timeout: Duration(seconds: Env.timeoutSeconds),
  )..addRequestModifier<dynamic>((request) async {
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

    // Restore the persisted access token so the session survives a refresh.
    _authToken = AuthStorage.accessToken;

    // Request modifier: inject auth headers, skip Content-Type on GET to avoid
    // unnecessary CORS preflight OPTIONS requests.
    httpClient.addRequestModifier<dynamic>((request) async {
      _applyRequestModifiers(request);
      return request;
    });
  }

  /// POST /auth/refresh. Returns true when a new access token was obtained.
  Future<bool> _refreshAccessToken() async {
    final refreshToken = AuthStorage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    if (_isRefreshing) {
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _authToken != null && _authToken!.isNotEmpty;
    }

    _isRefreshing = true;
    try {
      // Use super.post directly so a 401 on the refresh endpoint doesn't
      // trigger another refresh attempt (infinite loop).
      final response = await super.post(
        Env.refreshPath,
        {'refresh_token': refreshToken},
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

      final dataMap = (json['data'] is Map) ? Map<String, dynamic>.from(json['data']) : json;
      final newAccessToken = (dataMap['access_token'] ?? json['access_token'] ?? '').toString();
      final newRefreshToken = (dataMap['refresh_token'] ?? refreshToken).toString();
      final newExpiresIn = dataMap['expiresIn'] ?? dataMap['expires_in'] ?? json['expiresIn'] ?? json['expires_in'];

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
  /// the user or redirecting away from the current page (e.g. search results).
  void _clearExpiredToken() {
    _authToken = null;
    AuthStorage.clearTokens();
  }

  Future<void> _ensureFreshTokenIfNeeded(String? url) async {
    if (url != null && _isPublicAuthEndpoint(Uri.parse(url))) {
      return;
    }
    if (_authToken != null && AuthStorage.isAccessTokenExpired) {
      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        _clearExpiredToken();
      }
    }
  }

  Future<Response<T>> _getWithRefresh<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) async {
    await _ensureFreshTokenIfNeeded(url);

    final response = await super.get<T>(
      url,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
    );

    if (response.statusCode == 401 && !_isPublicAuthEndpoint(Uri.parse(url))) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return super.get<T>(
          url,
          headers: headers,
          contentType: contentType,
          query: query,
          decoder: decoder,
        );
      }
      _clearExpiredToken();
      return super.get<T>(
        url,
        headers: headers,
        contentType: contentType,
        query: query,
        decoder: decoder,
      );
    }

    return response;
  }

  Future<Response<T>> _postWithRefresh<T>(
    String? url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) async {
    await _ensureFreshTokenIfNeeded(url);

    final response = await super.post<T>(
      url,
      body,
      contentType: contentType,
      headers: headers,
      query: query,
      decoder: decoder,
      uploadProgress: uploadProgress,
    );

    if (response.statusCode == 401 &&
        (url == null || !_isPublicAuthEndpoint(Uri.parse(url)))) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return super.post<T>(
          url,
          body,
          contentType: contentType,
          headers: headers,
          query: query,
          decoder: decoder,
          uploadProgress: uploadProgress,
        );
      }
      _clearExpiredToken();
      return super.post<T>(
        url,
        body,
        contentType: contentType,
        headers: headers,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      );
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
  }) async {
    if (kIsWeb && Env.useCorsProxy && _useWebCorsProxy) {
      return _proxyClient.get<T>(
        url,
        headers: headers,
        contentType: contentType,
        query: query,
        decoder: decoder,
      );
    }

    final response = await _getWithRefresh<T>(
      url,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
    );

    // On Flutter Web, if the backend lacks Access-Control-Allow-Origin headers
    // for the page's origin, XMLHttpRequest fails with statusCode == null
    // ("XMLHttpRequest error."). Fall back to the local dev CORS proxy on
    // 127.0.0.1:8787 so Chrome can run without --disable-web-security.
    if (kIsWeb && Env.useCorsProxy && response.statusCode == null) {
      return _viaCorsProxy<T>(
        () => _proxyClient.get<T>(
          url,
          headers: headers,
          contentType: contentType,
          query: query,
          decoder: decoder,
        ),
      );
    }

    return response;
  }

  /// Fall back to the local dev CORS proxy (http://127.0.0.1:8787) when a
  /// direct browser XHR failed with `statusCode == null` ("XMLHttpRequest
  /// error.", i.e. the request was CORS- or network-blocked).
  ///
  /// Returns the proxied response when the proxy is reachable, and marks the
  /// proxy as the preferred transport for the rest of the session. Throws a
  /// descriptive error when the proxy is not running so callers can surface an
  /// actionable message instead of the opaque "XMLHttpRequest error."
  Future<Response<T>> _viaCorsProxy<T>(
    Future<Response<T>> Function() fetch,
  ) async {
    try {
      final proxyResponse = await fetch();
      if (proxyResponse.statusCode != null) {
        _useWebCorsProxy = true;
        return proxyResponse;
      }
    } catch (_) {
      // Proxy not reachable.
    }
    throw 'The local CORS proxy at http://127.0.0.1:8787 is not running. '
        'Start it with `dart run tool/cors_proxy.dart` (or ./run_web.sh), '
        'then reload the page.';
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
  }) async {
    if (kIsWeb && Env.useCorsProxy && _useWebCorsProxy) {
      return _proxyClient.post<T>(
        url,
        body: body,
        contentType: contentType,
        headers: headers,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      );
    }

    final response = await _postWithRefresh<T>(
      url,
      body,
      contentType: contentType,
      headers: headers,
      query: query,
      decoder: decoder,
      uploadProgress: uploadProgress,
    );

    if (kIsWeb && Env.useCorsProxy && response.statusCode == null) {
      return _viaCorsProxy<T>(
        () => _proxyClient.post<T>(
          url,
          body: body,
          contentType: contentType,
          headers: headers,
          query: query,
          decoder: decoder,
          uploadProgress: uploadProgress,
        ),
      );
    }

    return response;
  }

  @override
  void dispose() {
    _proxyClient.close();
    super.dispose();
  }
}
