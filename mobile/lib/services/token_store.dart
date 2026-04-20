import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  static const _tokenKey = 'auth_token';
  static const _storage = FlutterSecureStorage();

  String? _token;

  TokenStore._(this._token);

  static Future<TokenStore> create() async {
    final token = await _storage.read(key: _tokenKey);
    return TokenStore._(token);
  }

  String? readToken() {
    return _token;
  }

  Future<void> saveToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clear() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }
}
