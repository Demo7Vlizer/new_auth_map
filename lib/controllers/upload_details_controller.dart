import 'dart:io';

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
      // Fetch user details from the API
      final userDetails = await fetchUserDetails();
      if (userDetails != null) {
        // Upload image to Cloudinary
        final cloudinaryResponse = await uploadImageToCloudinary(selectedImage.value!);
        if (cloudinaryResponse != null) {
          // Save user details to the API
          await saveUserDetails(userDetails, cloudinaryResponse);
          Get.snackbar('Success', 'Details uploaded successfully!');
        } else {
          Get.snackbar('Error', 'Failed to upload image.');
        }
      } else {
        Get.snackbar('Error', 'Failed to fetch user details.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload details: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> fetchUserDetails() async {
    final response = await http.get(Uri.parse('https://67b6ba3307ba6e590841767c.mockapi.io/api/v1/users'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data.isNotEmpty ? data[0] : null;
    }
    return null;
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

  Future<void> saveUserDetails(Map<String, dynamic> userDetails, String imageUrl) async {
    final response = await http.post(
      Uri.parse('https://67b82d462bddacfb271144b3.mockapi.io/api/v1/userDetails'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': userDetails['user_details']['name'],
        'email': userDetails['user_details']['email'],
        'phone': userDetails['user_details']['phone'],
        'location': userDetails['user_details']['location'],
        'image': imageUrl,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to save user details');
    }
  }
} 