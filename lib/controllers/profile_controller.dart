// ignore_for_file: unused_local_variable, avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'auth_controller.dart';

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
    if (selectedImage.value != null) {
        // Prevent picking a new image if one is already selected
        Get.snackbar('Error', 'An image is already selected. Please update or remove it first.');
        return;
    }

    final picker = ImagePicker();
    try {
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
            selectedImage.value = File(pickedFile.path);
        }
    } catch (e) {
        Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> updateProfile() async {
    try {
        if (currentUser == null || currentUser!.id.isEmpty) {
            print('Invalid user state - ID: ${currentUser?.id}'); // Debug log
            throw Exception('Invalid user ID. Please login again.');
        }

        print('Current user before update: ${currentUser!.toJson()}');
        
        isLoading.value = true;
        String? imageUrl;
        
        if (selectedImage.value != null) {
            try {
                imageUrl = await _cloudinaryService.uploadImage(selectedImage.value!);
            } catch (e) {
                throw Exception('Failed to upload image: $e');
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

        print('Attempting to update user: ${updatedUser.toJson()}');

        await _userService.updateUser(updatedUser);
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
        
    } catch (e) {
        print('Update error: $e');
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