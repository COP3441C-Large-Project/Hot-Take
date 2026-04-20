import 'auth_user.dart';

class AuthSession {
  final String token;
  final AuthUser user;

  const AuthSession({
    required this.token,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final rawToken = json['token'];
    final token = rawToken is String ? rawToken.trim() : '';
    if (token.isEmpty) {
      throw const FormatException('Missing auth token.');
    }

    return AuthSession(
      token: token,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
    );
  }
}
