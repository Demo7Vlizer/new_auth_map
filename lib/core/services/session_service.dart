import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user_model.dart';

class SessionService {
  static const String _userBox = 'users';
  static const String _sessionKey = 'current_user';
  static const String _firstTimeKey = 'first_time';
  static const String _lastActiveKey = 'last_active';
  static const int _sessionExpiryDays = 30; // Session expires after 30 days

  Box<UserModel>? _box;
  Box<dynamic>? _settingsBox;

  bool get isInitialized => _box != null && _settingsBox != null;

  Future<void> init() async {
    if (!isInitialized) {
      print('Initializing SessionService...');
      await Hive.initFlutter();
      
      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        print('Registering UserModelAdapter...');
        Hive.registerAdapter(UserModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        print('Registering LocationAdapter...');
        Hive.registerAdapter(LocationAdapter());
      }

      _box = await Hive.openBox<UserModel>(_userBox);
      _settingsBox = await Hive.openBox('settings');
      
      print('SessionService initialized successfully');
      
      final currentUser = getCurrentUser();
      if (currentUser != null) {
        print('Found existing user: ${currentUser.name}');
        await updateLastActive();
      } else {
        print('No existing user found');
      }
    }
  }

  Future<void> saveUser(UserModel user) async {
    print('Saving user: ${user.name}');
    if (!isInitialized) await init();
    await _box?.put(_sessionKey, user);
    await updateLastActive();
    print('User saved successfully');
  }

  UserModel? getCurrentUser() {
    if (!isInitialized) {
      print('SessionService not initialized when getting current user');
      return null;
    }
    final user = _box?.get(_sessionKey);
    print('Getting current user: ${user?.name ?? 'null'}');
    return user;
  }

  Future<void> clearSession() async {
    print('Clearing session...');
    if (!isInitialized) await init();
    await _box?.delete(_sessionKey);
    await _settingsBox?.delete(_lastActiveKey);
    print('Session cleared');
  }

  bool isFirstTime() {
    if (!isInitialized) return true;
    return _settingsBox?.get(_firstTimeKey, defaultValue: true) ?? true;
  }

  Future<void> setFirstTimeDone() async {
    if (!isInitialized) await init();
    await _settingsBox?.put(_firstTimeKey, false);
  }

  Future<void> updateLastActive() async {
    final timestamp = DateTime.now().toIso8601String();
    print('Updating last active timestamp: $timestamp');
    await _settingsBox?.put(_lastActiveKey, timestamp);
  }

  bool isSessionValid() {
    if (!isInitialized) {
      print('Session validation failed: not initialized');
      return false;
    }
    
    final lastActiveStr = _settingsBox?.get(_lastActiveKey);
    if (lastActiveStr == null) {
      print('Session validation failed: no last active timestamp');
      return false;
    }
    
    final lastActive = DateTime.parse(lastActiveStr);
    final now = DateTime.now();
    final difference = now.difference(lastActive).inDays;
    
    final user = getCurrentUser();
    final isValid = user != null && difference < _sessionExpiryDays;
    
    print('Session validation: user exists: ${user != null}, days since last active: $difference');
    print('Session is ${isValid ? 'valid' : 'invalid'}');
    
    return isValid;
  }
} 