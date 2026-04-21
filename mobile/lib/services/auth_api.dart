import 'dart:async';
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
  static const Duration _requestTimeout = Duration(seconds: 10);

  final String baseUrl;
  final http.Client _client;

  AuthApi({String? baseUrl, http.Client? client})
      : baseUrl = _resolveBaseUrl(baseUrl),
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
    final response = await _timedRequest(
      () => _client.get(
        Uri.parse('$baseUrl/api/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final payload = _decodePayload(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AuthUser.fromJson(payload['user'] as Map<String, dynamic>? ?? const <String, dynamic>{});
    }

    throw AuthApiException(response.statusCode, _messageFromPayload(payload));
  }

  Future<AuthSession> _postSession(String path, Map<String, dynamic> body) async {
    final response = await _timedRequest(
      () => _client.post(
        Uri.parse('$baseUrl$path'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ),
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

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      return const <String, dynamic>{};
    }

    return const <String, dynamic>{};
  }

  String _messageFromPayload(Map<String, dynamic> payload) {
    return payload['error'] as String? ?? 'Something went wrong.';
  }

  Future<void> sendVerificationEmail(String userId) async {
    final response = await _timedRequest(
      () => _client.post(
        Uri.parse('$baseUrl/api/auth/send-verification'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final payload = _decodePayload(response);
      throw AuthApiException(response.statusCode, _messageFromPayload(payload));
    }
  }

  static String _resolveBaseUrl(String? baseUrl) {
    final value = baseUrl ?? _defaultBaseUrl();
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) {
      throw ArgumentError('Invalid API base URL.');
    }
    return value;
  }

  static String _defaultBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    return 'http://167.99.155.122'; // same for all platforms
  }

  static bool _isLocalHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'localhost' || normalized == '127.0.0.1' || normalized == '10.0.2.2';
  }

  Future<http.Response> _timedRequest(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException {
      throw const AuthApiException(408, 'Request timed out.');
    }
  }
}

