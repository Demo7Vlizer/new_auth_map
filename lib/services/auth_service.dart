import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class AuthService extends ChangeNotifier {
  final UserService _userService = UserService();
  UserModel? _currentUser;
  
  UserModel? get currentUser => _currentUser;

  Future<bool> verifyPhone(String phoneNumber) async {
    try {
      // Simulate OTP sent
      print('OTP sent to $phoneNumber');
      return true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    try {
      // Demo verification - in real app, verify with backend
      if (otp == '123456') {
        final user = UserModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'New User',
          email: '',
          phone: phoneNumber,
          location: Location(latitude: 0, longitude: 0),
        );
        
        _currentUser = await _userService.createUser(user);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  Future<void> updateUserProfile({
    required String name,
    required String email,
    required Location location,
  }) async {
    if (_currentUser != null) {
      final updatedUser = UserModel(
        id: _currentUser!.id,
        name: name,
        email: email,
        phone: _currentUser!.phone,
        location: location,
        image: _currentUser!.image,
      );
      await _userService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    }
  }
}