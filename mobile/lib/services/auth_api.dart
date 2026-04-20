import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/auth_session.dart';
import '../models/auth_user.dart';

class AuthApiException implements Exception {
  final int statusCode;
  final String message;

  const AuthApiException(this.statusCode, this.message);

  @override
  String toString() => 'AuthApiException($statusCode, $message)';
}

class AuthApi {
  final String baseUrl;
  final http.Client _client;

  AuthApi({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? _defaultBaseUrl(),
        _client = client ?? http.Client();

  Future<AuthSession> login({
    required String email,
    required String password,
  }) {
    return _postSession('/api/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
  }) {
    return _postSession('/api/auth/register', {
      'username': username,
      'email': email,
      'password': password,
    });
  }

  Future<AuthUser> me(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final payload = _decodePayload(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AuthUser.fromJson(payload['user'] as Map<String, dynamic>? ?? const <String, dynamic>{});
    }

    throw AuthApiException(response.statusCode, _messageFromPayload(payload));
  }

  Future<AuthSession> _postSession(String path, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final payload = _decodePayload(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AuthSession.fromJson(payload);
    }

    throw AuthApiException(response.statusCode, _messageFromPayload(payload));
  }

  Map<String, dynamic> _decodePayload(http.Response response) {
    if (response.body.isEmpty) {
      return const <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return const <String, dynamic>{};
  }

  String _messageFromPayload(Map<String, dynamic> payload) {
    return payload['error'] as String? ?? 'Something went wrong.';
  }

  Future<void> sendVerificationEmail(String userId) async {
  final response = await _client.post(
    Uri.parse('$baseUrl/api/auth/send-verification'),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({'userId': userId}),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    final payload = _decodePayload(response);
    throw AuthApiException(response.statusCode, _messageFromPayload(payload));
  }
}

  static String _defaultBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:3001'; 
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:3001';
      case TargetPlatform.android:
        return 'http://10.0.2.2:3001';
      case TargetPlatform.macOS:
        return 'http://127.0.0.1:3001';
      case TargetPlatform.windows:
        return 'http://127.0.0.1:3001';
      case TargetPlatform.linux:
        return 'http://127.0.0.1:3001';
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:3001';
      default:
        return 'http://167.99.155.122:3001';
    }
  }
}

