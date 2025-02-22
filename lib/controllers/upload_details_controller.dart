import 'dart:io';

import 'package:auth_map/controllers/auth_controller.dart';
import 'package:auth_map/models/user_model.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UploadDetailsController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final Rx<File?> selectedImage = Rx<File?>(null);
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final RxBool isLoading = false.obs;
  final _authController = Get.find<AuthController>();

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      selectedImage.value = File(pickedFile.path);
    }
  }

  Future<void> uploadDetails() async {
    if (selectedImage.value == null) {
      Get.snackbar('Error', 'Please select an image.');
      return;
    }

    isLoading.value = true;

    try {
      // Get current user ID
      final currentUser = _authController.currentUser.value;
      if (currentUser == null) {
        Get.snackbar('Error', 'User not logged in');
        return;
      }

      // Upload image to Cloudinary
      final cloudinaryResponse = await uploadImageToCloudinary(selectedImage.value!);
      if (cloudinaryResponse != null) {
        // Save user details to the API with current user's ID
        await saveUserDetails(currentUser, cloudinaryResponse);
        Get.snackbar('Success', 'Details uploaded successfully!');
      } else {
        Get.snackbar('Error', 'Failed to upload image.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload details: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> uploadImageToCloudinary(File image) async {
    final url = 'https://api.cloudinary.com/v1_1/db0v7yf9v/image/upload';
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields['upload_preset'] = 'Auth_Map';
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);

    if (response.statusCode == 200) {
      final data = json.decode(responseData.body);
      return data['secure_url']; // Return the URL of the uploaded image
    }
    return null;
  }

  Future<void> saveUserDetails(UserModel currentUser, String imageUrl) async {
    final response = await http.post(
      Uri.parse('https://67b82d462bddacfb271144b3.mockapi.io/api/v1/userDetails'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id': currentUser.id, // Use current user's ID
        'name': currentUser.name,
        'email': currentUser.email,
        'phone': currentUser.phone,
        'location': currentUser.location.toJson(),
        'image': imageUrl,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to save user details');
    }
  }
} 