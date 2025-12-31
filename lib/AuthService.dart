import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  String? _token;
  String? _email;

  Future<void> saveLogin(String email, String token) async {
    final prefs = await SharedPreferences.getInstance();
    _email = email;
    _token = token;
    await prefs.setString('email', email);
    await prefs.setString('token', token);
  }

  Future<void> loadLogin() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString('email');
    _token = prefs.getString('token');
  }

  String get currentUserEmail => _email ?? '';
  String get token => _token ?? '';

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('token');
    _email = null;
    _token = null;
  }

  bool get isLoggedIn => _token != null;
}
