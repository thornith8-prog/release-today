import 'dart:convert';

import 'package:get/get.dart';

import '../../core/env.dart';
import '../../services/api_client.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthUserSummary {
  const AuthUserSummary({
    required this.userId,
    required this.username,
    required this.role,
    this.email,
    this.isActive = true,
    this.isVerified = false,
    this.firstName,
    this.lastName,
  });

  final String userId;
  final String username;
  final String? email;
  final String role;
  final bool isActive;
  final bool isVerified;
  final String? firstName;
  final String? lastName;

  String get displayName {
    final fullName = [firstName, lastName]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(' ');
    if (fullName.isNotEmpty) return fullName;
    if (username.trim().isNotEmpty) return username.trim();
    if (email != null && email!.trim().isNotEmpty) {
      return email!.split('@').first;
    }
    return 'User';
  }

  factory AuthUserSummary.fromJson(Map<String, dynamic> json) {
    return AuthUserSummary(
      userId: (json['user_id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: json['email']?.toString(),
      role: (json['role'] ?? 'USER_ROLE').toString(),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      isVerified: json['is_verified'] is bool ? json['is_verified'] as bool : false,
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'role': role,
      'is_active': isActive,
      'is_verified': isVerified,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}

class AuthTokenResult {
  const AuthTokenResult({
    required this.accessToken,
    required this.expiresIn,
    required this.user,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.message = '',
  });

  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int expiresIn;
  final AuthUserSummary user;
  final String message;
}

class AuthActionResult {
  const AuthActionResult({
    required this.message,
    this.user,
  });

  final String message;
  final AuthUserSummary? user;
}

class AuthRepository {
  const AuthRepository(this.api);

  final ApiClient api;

  Map<String, dynamic>? _tryDecodeMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _extractErrorMessage(Response<dynamic> response, String fallback) {
    final map = _tryDecodeMap(response.body);
    if (map != null) {
      final message = map['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      final detail = map['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
      if (detail is List && detail.isNotEmpty) {
        final messages = <String>[];
        for (final item in detail) {
          if (item is Map) {
            final msg = item['msg']?.toString().trim();
            if (msg != null && msg.isNotEmpty) {
              messages.add(msg);
            }
          }
        }
        if (messages.isNotEmpty) {
          return messages.join('. ');
        }
      }
    }
    if (response.statusCode == null) {
      return 'Unable to reach server. Please check your connection and try again.';
    }
    return fallback;
  }

  Map<String, dynamic> _unwrapApiResponse(
    Response<dynamic> response, {
    required String fallbackError,
  }) {
    final body = _tryDecodeMap(response.body);
    if (response.status.hasError || body == null) {
      throw AuthApiException(
        _extractErrorMessage(response, fallbackError),
        statusCode: response.statusCode,
      );
    }

    final status = body['status']?.toString().toLowerCase();
    final code = body['code'];
    if (status == 'error' || (code is int && code >= 400)) {
      throw AuthApiException(
        _extractErrorMessage(response, fallbackError),
        statusCode: response.statusCode,
      );
    }
    return body;
  }

  /// POST /auth/register
  Future<AuthActionResult> register({
    required String email,
    required String password,
  }) async {
    final response = await api.post<dynamic>(
      Env.registerPath,
      {
        'email': email.trim(),
        'password': password.trim(),
      },
    );

    final body = _unwrapApiResponse(
      response,
      fallbackError: 'Sign up failed. Please check your details and try again.',
    );

    final dataMap = _tryDecodeMap(body['data']);
    final user = dataMap != null ? AuthUserSummary.fromJson(dataMap) : null;
    final message = (body['message']?.toString().trim().isNotEmpty ?? false)
        ? body['message'].toString().trim()
        : 'Verification code sent to your email.';

    return AuthActionResult(message: message, user: user);
  }

  /// POST /auth/verify-email
  Future<AuthActionResult> verifyEmail({
    required String email,
    required String otpCode,
  }) async {
    final response = await api.post<dynamic>(
      Env.verifyEmailPath,
      {
        'email': email.trim(),
        'otp_code': otpCode.trim(),
      },
    );

    final body = _unwrapApiResponse(
      response,
      fallbackError: 'Invalid or expired verification code. Please try again.',
    );

    final dataMap = _tryDecodeMap(body['data']);
    final user = dataMap != null ? AuthUserSummary.fromJson(dataMap) : null;
    final message = (body['message']?.toString().trim().isNotEmpty ?? false)
        ? body['message'].toString().trim()
        : 'Email verified successfully.';

    return AuthActionResult(message: message, user: user);
  }

  /// POST /auth/resend-otp
  Future<String> resendOtp({required String email}) async {
    final response = await api.post<dynamic>(
      Env.resendOtpPath,
      {
        'email': email.trim(),
      },
    );

    final body = _unwrapApiResponse(
      response,
      fallbackError: 'Could not resend verification code. Please try again.',
    );

    final dataMap = _tryDecodeMap(body['data']);
    final dataMsg = dataMap?['message']?.toString().trim();
    final topMsg = body['message']?.toString().trim();
    if (dataMsg != null && dataMsg.isNotEmpty) return dataMsg;
    if (topMsg != null && topMsg.isNotEmpty) return topMsg;
    return 'A new 6-digit verification code has been sent to your email.';
  }

  /// POST /auth/login
  Future<AuthTokenResult> login({
    required String username,
    required String password,
  }) async {
    final response = await api.post<dynamic>(
      Env.loginPath,
      {
        'username': username.trim(),
        'password': password.trim(),
      },
    );

    final body = _unwrapApiResponse(
      response,
      fallbackError: 'Invalid email or password.',
    );

    final dataMap = _tryDecodeMap(body['data']);
    if (dataMap == null) {
      throw const AuthApiException('Unexpected login response from server.');
    }

    final accessToken = (dataMap['access_token'] ?? '').toString();
    if (accessToken.isEmpty) {
      throw const AuthApiException('Authentication token missing from response.');
    }

    final userMap = _tryDecodeMap(dataMap['user']) ?? <String, dynamic>{};
    final user = AuthUserSummary.fromJson(userMap);

    return AuthTokenResult(
      accessToken: accessToken,
      refreshToken: dataMap['refresh_token']?.toString(),
      tokenType: (dataMap['token_type'] ?? 'Bearer').toString(),
      expiresIn: dataMap['expires_in'] is int
          ? dataMap['expires_in'] as int
          : int.tryParse(dataMap['expires_in']?.toString() ?? '300') ?? 300,
      user: user,
      message: (body['message'] ?? '').toString(),
    );
  }
}
