import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

class StorageService {
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyUserData = 'auth_user_data';
  static const String _keyRememberMe = 'auth_remember_me';
  static const String _keySavedLogin = 'auth_saved_login';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Future<void> saveAuthSession({
    required UserModel? user,
    required AuthTokens? tokens,
    bool rememberMe = true,
  }) async {
    if (tokens != null) {
      await _prefs.setString(_keyAccessToken, tokens.access);
      await _prefs.setString(_keyRefreshToken, tokens.refresh);
    }
    if (user != null) {
      await _prefs.setString(_keyUserData, jsonEncode(user.toJson()));
    }
    await _prefs.setBool(_keyRememberMe, rememberMe);
  }

  Future<void> saveRememberedLogin(String login) async {
    await _prefs.setString(_keySavedLogin, login);
  }

  String? getSavedLogin() {
    return _prefs.getString(_keySavedLogin);
  }

  bool getRememberMe() {
    return _prefs.getBool(_keyRememberMe) ?? false;
  }

  String? getAccessToken() {
    return _prefs.getString(_keyAccessToken);
  }

  String? getRefreshToken() {
    return _prefs.getString(_keyRefreshToken);
  }

  UserModel? getUser() {
    final userString = _prefs.getString(_keyUserData);
    if (userString == null) return null;
    try {
      final map = jsonDecode(userString) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  bool isLoggedIn() {
    final token = getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAuthSession() async {
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyUserData);
  }
}
