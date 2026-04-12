class TokenStore {
  String? _token;

  TokenStore();

  static Future<TokenStore> create() async {
    return TokenStore();
  }

  String? readToken() {
    return _token;
  }

  Future<void> saveToken(String token) async {
    _token = token;
  }

  Future<void> clear() async {
    _token = null;
  }
}
