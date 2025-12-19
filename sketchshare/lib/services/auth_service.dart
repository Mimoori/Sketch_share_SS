import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Временный метод для тестирования - создает тестовый токен
  Future<String> getTestToken() async {
    // В реальном приложении это должно приходить с сервера после входа
    // Здесь временно возвращаем тестовый токен
    await saveToken('test_jwt_token_for_demo');
    return 'test_jwt_token_for_demo';
  }
}