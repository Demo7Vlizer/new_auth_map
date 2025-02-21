import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';

class SessionService {
  static const String KEY_USER = 'user_data';
  static const String KEY_AUTH_TOKEN = 'auth_token';
  
  Future<void> saveSession(UserModel user, String authToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_USER, jsonEncode(user.toJson()));
    await prefs.setString(KEY_AUTH_TOKEN, authToken);
  }

  Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(KEY_USER);
    final authToken = prefs.getString(KEY_AUTH_TOKEN);
    return userData != null && authToken != null;
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(KEY_USER);
    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }
    return null;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_USER);
    await prefs.remove(KEY_AUTH_TOKEN);
  }
} 