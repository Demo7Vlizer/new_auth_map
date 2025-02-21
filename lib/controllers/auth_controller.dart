import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../core/services/session_service.dart';
import 'package:flutter/services.dart';
import '../controllers/map_controller.dart';

class AuthController extends GetxController {
  final SessionService sessionService;
  final UserService _userService = UserService();
  final RxBool isLoading = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  String? _generatedOTP;
  Timer? _locationTimer;

  AuthController({required this.sessionService});

  @override
  void onInit() {
    super.onInit();
    ever(currentUser, (user) {
      if (user != null) {
        _startLocationUpdates();
      } else {
        _locationTimer?.cancel();
      }
    });
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    try {
      print('Initializing session in AuthController...');
      if (!sessionService.isInitialized) {
        await sessionService.init();
      }

      if (await sessionService.isSessionValid()) {
        final savedUser = await sessionService.getCurrentUser();
        print('Found valid session for user: ${savedUser?.name}');

        if (savedUser != null) {
          currentUser.value = savedUser;
          try {
            final location = await _getCurrentLocation();
            await updateUserProfile(
              name: savedUser.name,
              email: savedUser.email,
              location: location,
            );
            print('Updated user location successfully');
          } catch (e) {
            print('Error updating location: $e');
          }
        }
      } else {
        print('No valid session found');
      }
    } catch (e) {
      print('Error initializing session: $e');
    }
  }

  Future<Location> _getCurrentLocation() async {
    try {
      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return Location(latitude: 0, longitude: 0);
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return Location(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      print('Error getting location: $e');
      return Location(latitude: 0, longitude: 0);
    }
  }

  String _generateOTP() {
    final otp = (100000 + DateTime.now().microsecond % 900000).toString();
    _generatedOTP = otp;
    return otp;
  }

  Future<bool> verifyPhone(String phoneNumber) async {
    try {
      isLoading.value = true;

      // Check if phone number already exists
      final users = await _userService.getAllUsers();
      final phoneExists = users.any((user) => user.phone == '+91$phoneNumber');

      if (phoneExists) {
        Get.snackbar(
          'Error',
          'This phone number is already registered',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          margin: const EdgeInsets.all(16),
          borderRadius: 16,
        );
        return false;
      }

      final otp = _generateOTP();

      Get.snackbar(
        '',
        '',
        titleText: const Text(
          'OTP Sent Successfully!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        messageText: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Use this OTP for testing:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: otp));
                Get.snackbar(
                  'Success',
                  'OTP copied to clipboard',
                  backgroundColor: Colors.green.shade100,
                  duration: const Duration(seconds: 1),
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      otp,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.copy,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sent to: +91 $phoneNumber',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.blue.shade700,
        colorText: Colors.white,
        borderRadius: 16,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        snackPosition: SnackPosition.TOP,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send OTP: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    try {
      isLoading.value = true;
      if (otp == _generatedOTP) {
        // Get current location
        final location = await _getCurrentLocation();

        // Create new user
        final user = UserModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'New User',
          email: '',
          phone: '+91$phoneNumber',
          location: location,
        );

        try {
          // Create user in service
          final createdUser = await _userService.createUser(user);

          // Update current user and save to session
          currentUser.value = createdUser;
          await sessionService.saveSession(createdUser, 'auth_token_here');

          // Navigate to map screen after successful verification
          Get.offAllNamed('/map');

          return true;
        } catch (e) {
          print('Error creating user: $e');
          Get.snackbar(
            'Error',
            'Failed to create user account. Please try again.',
            backgroundColor: Colors.red.shade100,
          );
          return false;
        }
      }

      Get.snackbar(
        'Invalid OTP',
        'Please enter the correct OTP',
        backgroundColor: Colors.red.shade100,
      );
      return false;
    } catch (e) {
      print('Verification error: $e');
      Get.snackbar(
        'Error',
        'Verification failed. Please try again.',
        backgroundColor: Colors.red.shade100,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserProfile({
    required String name,
    required String email,
    required Location location,
  }) async {
    try {
      isLoading.value = true;

      if (currentUser.value == null) {
        throw Exception('No user logged in');
      }

      final updatedUser = currentUser.value!.copyWith(
        name: name,
        email: email,
        location: location,
      );

      // Update in service
      await _userService.updateUser(updatedUser);

      // Update local state
      currentUser.value = updatedUser;

      // Save to session
      await sessionService.saveSession(updatedUser, 'auth_token_here');

      // Force refresh users list
      Get.find<MapController>().loadUsers();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile: $e',
        backgroundColor: Colors.red.shade100,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updateUserLocation();
    });
  }

  Future<void> _updateUserLocation() async {
    if (currentUser.value != null) {
      final location = await _getCurrentLocation();
      await _userService.updateUserLocation(currentUser.value!.id, location);
    }
  }

  Future<void> logout() async {
    try {
      _locationTimer?.cancel();
      await sessionService.clearSession();
      currentUser.value = null;
      Get.offAllNamed('/welcome');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Future<bool> checkUserExists(String phoneNumber) async {
    try {
      final users = await _userService.getAllUsers();
      return users.any((user) => user.phone == '+91$phoneNumber');
    } catch (e) {
      print('Error checking user: $e');
      return false;
    }
  }

  Future<bool> sendLoginOTP(String phoneNumber) async {
    try {
      isLoading.value = true;
      final userExists = await checkUserExists(phoneNumber);

      if (!userExists) {
        Get.snackbar(
          'Error',
          'Phone number not registered. Please register first.',
          backgroundColor: Colors.red.shade100,
        );
        return false;
      }

      final otp = _generateOTP();
      // Show OTP notification
      _showOTPNotification(otp, phoneNumber);
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send OTP: $e',
        backgroundColor: Colors.red.shade100,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyLoginOTP(String phone, String otp) async {
    try {
      isLoading.value = true;
      final user = await _userService.verifyOTP(phone, otp);
      if (user != null) {
        // Save session data
        await sessionService.saveSession(user, 'auth_token_here');
        currentUser.value = user;
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      Get.snackbar(
        'Error',
        'Verification failed. Please try again.',
        backgroundColor: Colors.red.shade100,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void _showOTPNotification(String otp, String phoneNumber) {
    Get.snackbar(
      'OTP Sent Successfully!',
      '',
      titleText: const Text(
        'OTP Sent Successfully!',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      messageText: _buildOTPMessage(otp, phoneNumber),
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.blue.shade700,
      colorText: Colors.white,
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      snackPosition: SnackPosition.TOP,
    );
  }

  Widget _buildOTPMessage(String otp, String phoneNumber) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Use this OTP for testing:',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: otp));
            Get.snackbar(
              'Success',
              'OTP copied to clipboard',
              backgroundColor: Colors.green.shade100,
              duration: const Duration(seconds: 1),
              snackPosition: SnackPosition.BOTTOM,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  otp,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.copy,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sent to: +91 $phoneNumber',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Future<Location> getCurrentLocation() async {
    return _getCurrentLocation();
  }
}
