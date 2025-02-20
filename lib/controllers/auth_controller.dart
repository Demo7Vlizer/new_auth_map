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

      if (sessionService.isSessionValid()) {
        final savedUser = sessionService.getCurrentUser();
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
        // Check if user exists
        final users = await _userService.getAllUsers();
        final existingUser =
            users.firstWhereOrNull((user) => user.phone == '+91$phoneNumber');

        UserModel user;

        if (existingUser != null) {
          // User exists, update their location
          final location = await _getCurrentLocation();
          user = UserModel(
            id: existingUser.id,
            name: existingUser.name,
            email: existingUser.email,
            phone: existingUser.phone,
            location: location,
            image: existingUser.image,
          );
          await _userService.updateUser(user);
        } else {
          // Create new user
          final location = await _getCurrentLocation();
          user = UserModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'New User',
            email: '',
            phone: '+91$phoneNumber',
            location: location,
          );
          user = await _userService.createUser(user);
        }

        // Save user to session
        currentUser.value = user;
        await sessionService.saveUser(user);

        Get.snackbar(
          'Success',
          'OTP verified successfully',
          backgroundColor: Colors.green.shade100,
        );
        return true;
      }

      Get.snackbar(
        'Invalid OTP',
        'Please enter the correct OTP',
        backgroundColor: Colors.red.shade100,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to verify OTP: $e',
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
      await sessionService.saveUser(updatedUser);

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
      await sessionService.clearSession();
      currentUser.value = null;
      await Get.offAllNamed('/welcome');
    } catch (e) {
      print('Logout error: $e');
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

  Future<bool> verifyLoginOTP(String phoneNumber, String otp) async {
    try {
      isLoading.value = true;
      if (otp == _generatedOTP) {
        final user = await _userService.getUserByPhone('+91$phoneNumber');
        if (user != null) {
          final location = await _getCurrentLocation();
          final updatedUser = user.copyWith(location: location);
          await _userService.updateUser(updatedUser);
          
          // Update current user and save to session
          currentUser.value = updatedUser;
          await sessionService.saveUser(updatedUser);
          print('User logged in successfully: ${updatedUser.name}');
          
          Get.offAllNamed('/map');
          return true;
        }
      }
      Get.snackbar(
        'Error',
        'Invalid OTP',
        backgroundColor: Colors.red.shade100,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Verification failed: $e',
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
