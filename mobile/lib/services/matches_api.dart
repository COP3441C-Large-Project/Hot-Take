import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match.dart';
import '../models/chat_message.dart';

class MatchesApiException implements Exception {
  final int statusCode;
  final String message;
  const MatchesApiException(this.statusCode, this.message);
}

class MatchesApi {
  final String baseUrl;
  final http.Client _client;

  MatchesApi({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? _defaultBaseUrl(),
        _client = client ?? http.Client();

  // Gets list of matches for current user
  Future<List<Match>> listMatches(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/matches'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final payload = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = payload['matches'] as List<dynamic>? ?? [];
      return list
          .map((m) => Match.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    throw MatchesApiException(response.statusCode, _error(payload));
  }

  // Starts or resumes a chat with a match, returns chatId
  Future<String> startChat(String token, String matchUserId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/matches/$matchUserId/start-chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final payload = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload['chatId'] as String? ?? '';
    }
    throw MatchesApiException(response.statusCode, _error(payload));
  }

  // Gets message history for a chat
  Future<List<Map<String, dynamic>>> getChatMessages(
      String token, String chatId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/chats/$chatId/messages'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final payload = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (payload['messages'] as List<dynamic>? ?? [])
          .map((m) => m as Map<String, dynamic>)
          .toList();
    }
    throw MatchesApiException(response.statusCode, _error(payload));
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return {};
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  String _error(Map<String, dynamic> payload) =>
      payload['error'] as String? ?? 'Something went wrong.';

  static String _defaultBaseUrl() {
    // Mirrors the same logic as AuthApi
    return 'http://127.0.0.1:3001';
  }
}