import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import 'dart:convert';

class SessionService {
  bool isInitialized = false;
  static const String KEY_USER = 'user_data';
  static const String KEY_AUTH_TOKEN = 'auth_token';
  
  Future<void> init() async {
    if (!isInitialized) {
      await SharedPreferences.getInstance();
      isInitialized = true;
    }
  }

  Future<void> saveSession(UserModel user, String authToken) async {
    if (user.id.isEmpty) {
        throw Exception('Cannot save session: User ID is empty');
    }
    
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
        final user = UserModel.fromJson(jsonDecode(userData));
        print('Retrieved user ID: ${user.id}');
        return user;
    }
    return null;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_USER);
    await prefs.remove(KEY_AUTH_TOKEN);
  }
} 