// ignore_for_file: unused_local_variable

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'auth_controller.dart';
import 'package:http/http.dart' as http;

class ProfileController extends GetxController {
  final _userService = UserService();
  final _cloudinaryService = CloudinaryService();
  final _authController = Get.find<AuthController>();
  
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  
  final RxBool isLoading = false.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);
  
  UserModel? get currentUser => _authController.currentUser.value;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    emailController = TextEditingController();
    // Ensure we have current user data
    if (currentUser == null) {
      Get.snackbar(
        'Error',
        'Session expired. Please login again.',
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );
      Get.offAllNamed('/auth'); // Redirect to auth screen
      return;
    }
    _loadUserData();
  }

  void _loadUserData() {
    if (currentUser != null) {
      nameController.text = currentUser!.name;
      emailController.text = currentUser!.email;
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      selectedImage.value = File(pickedFile.path);
    }
  }

  Future<void> updateProfile() async {
    try {
      // Validate if user exists
      if (currentUser == null) {
        throw Exception('No user found. Please login again.');
      }

      isLoading.value = true;
      
      String? imageUrl;
      if (selectedImage.value != null) {
        try {
          imageUrl = await _cloudinaryService.uploadImage(selectedImage.value!);
        } catch (e) {
          Get.snackbar(
            'Error',
            'Failed to upload image. Please try again.',
            backgroundColor: Colors.red.shade100,
            duration: const Duration(seconds: 3),
            snackPosition: SnackPosition.TOP,
          );
          return;
        }
      }

      final updatedUser = UserModel(
        id: currentUser!.id,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: currentUser!.phone,
        location: currentUser!.location,
        image: imageUrl ?? currentUser!.image,
      );

      // Validate required fields
      if (updatedUser.name.isEmpty) {
        throw Exception('Name is required');
      }

      // Log the user data being sent
      print('Updating user: ${updatedUser.toJson()}');

      final response = await http.put(
        Uri.parse('https://67b6ba3307ba6e590841767c.mockapi.io/api/v1/users/${currentUser?.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_details': {
            'name': updatedUser.name,
            'email': updatedUser.email,
            'phone': updatedUser.phone,
            'location': updatedUser.location.toJson(),
            'image': updatedUser.image,
          }
        }),
      );

      if (response.statusCode == 200) {
        _authController.currentUser.value = updatedUser;
        await _authController.sessionService.saveSession(updatedUser, 'auth_token_here');
        
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          backgroundColor: Colors.green.shade100,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
        );
        
        Get.back();
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }
} 