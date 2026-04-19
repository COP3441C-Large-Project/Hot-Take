import 'package:flutter/foundation.dart';
import '../models/match.dart';
import '../models/chat_message.dart';
import '../services/matches_api.dart';

class MatchesController extends ChangeNotifier {
  final MatchesApi _api;
  final String _token;
  final String _userId;

  List<Match> _matches = [];
  Match? _selectedMatch;
  String? _chatId;
  List<ChatMessage> _messages = [];
  bool _isBusy = false;
  bool _isLoadingChat = false;
  String? _error;

  MatchesController({
    required MatchesApi api,
    required String token,
    required String userId,
  })  : _api = api,
        _token = token,
        _userId = userId;

  List<Match> get matches => _matches;
  Match? get selectedMatch => _selectedMatch;
  String? get chatId => _chatId;
  List<ChatMessage> get messages => _messages;
  bool get isBusy => _isBusy;
  bool get isLoadingChat => _isLoadingChat;
  String? get error => _error;

  // Loads matches on page open
  Future<void> loadMatches() async {
    _isBusy = true;
    _error = null;
    notifyListeners();

    try {
      _matches = await _api.listMatches(_token);
      // Auto-select first match
      if (_matches.isNotEmpty) {
        await selectMatch(_matches.first);
      }
    } on MatchesApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Unable to load matches.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  // Selects a match and opens its chat
  Future<void> selectMatch(Match match) async {
    _selectedMatch = match;
    _chatId = null;
    _messages = [];
    _isLoadingChat = true;
    notifyListeners();

    try {
      final chatId = await _api.startChat(_token, match.userId);
      _chatId = chatId;

      final rawMessages = await _api.getChatMessages(_token, chatId);
      _messages = rawMessages
          .map((m) => ChatMessage.fromJson(m, _userId))
          .toList();
    } on MatchesApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Unable to load chat.';
    } finally {
      _isLoadingChat = false;
      notifyListeners();
    }
  }

  // Adds a message to the list (called by socket service)
  void addMessage(ChatMessage message) {
    _messages = [..._messages, message];
    notifyListeners();
  }

  // Replaces optimistic message with confirmed one from server
  void confirmMessage(String tempId, ChatMessage confirmed) {
    _messages = _messages.map((m) => m.id == tempId ? confirmed : m).toList();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}