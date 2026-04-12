import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import '../models/auth_user.dart';
import '../services/auth_api.dart';
import '../services/token_store.dart';

class AuthController extends ChangeNotifier {
  final AuthApi _api;
  final TokenStore _tokenStore;

  AuthUser? _user;
  String? _token;
  String? _error;
  bool _isBusy = false;
  bool _isRestoring = true;

  AuthController({
    required AuthApi api,
    required TokenStore tokenStore,
  })  : _api = api,
        _tokenStore = tokenStore;

  AuthUser? get user => _user;
  String? get token => _token;
  String? get error => _error;
  bool get isBusy => _isBusy;
  bool get isRestoring => _isRestoring;
  bool get isAuthenticated => _user != null && _token != null;

  Future<void> restoreSession() async {
    _isRestoring = true;
    notifyListeners();

    try {
      final storedToken = _tokenStore.readToken();
      if (storedToken == null || storedToken.isEmpty) {
        _clearSession();
        return;
      }

      final user = await _api.me(storedToken);
      _user = user;
      _token = storedToken;
      _error = null;
    } on AuthApiException {
      await _tokenStore.clear();
      _clearSession();
    } catch (_) {
      _clearSession();
      _error = null;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _submit(() => _api.login(email: email, password: password));
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await _submit(() => _api.register(username: username, email: email, password: password));
  }

  Future<void> logout() async {
    await _tokenStore.clear();
    _clearSession();
    notifyListeners();
  }

  void clearError() {
    if (_error == null) {
      return;
    }

    _error = null;
    notifyListeners();
  }

  Future<void> _submit(Future<AuthSession> Function() request) async {
    if (_isBusy) {
      return;
    }

    _isBusy = true;
    _error = null;
    notifyListeners();

    try {
      final session = await request();
      _user = session.user;
      _token = session.token;
      await _tokenStore.saveToken(session.token);
    } on AuthApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Unable to reach the server.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _clearSession() {
    _user = null;
    _token = null;
    _error = null;
  }
}
