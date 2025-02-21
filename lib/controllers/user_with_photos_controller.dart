import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_with_photos.dart';

class UserWithPhotosController extends GetxController {
  var usersWithPhotos = <UserWithPhotos>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchUsersWithPhotos();
    super.onInit();
  }

  Future<void> fetchUsersWithPhotos() async {
    try {
      isLoading.value = true;

      // Fetch user data
      final userResponse = await http.get(Uri.parse('https://67b6ba3307ba6e590841767c.mockapi.io/api/v1/users'));
      final userDetailsResponse = await http.get(Uri.parse('https://67b82d462bddacfb271144b3.mockapi.io/api/v1/userDetails'));

      if (userResponse.statusCode == 200 && userDetailsResponse.statusCode == 200) {
        final List<dynamic> userData = json.decode(userResponse.body);
        final List<dynamic> userDetailsData = json.decode(userDetailsResponse.body);

        // Map user data to UserWithPhotos
        usersWithPhotos.value = userData.map((user) {
          final userDetails = userDetailsData.firstWhere((details) => details['id'] == user['id'], orElse: () => null);
          final photos = userDetails != null 
              ? List<String>.from(userDetails['photos']?.map((photo) => photo.toString()) ?? []) 
              : [];
          print('User: ${userDetails['name']}, Photos: ${userDetails['photos']}');
          return UserWithPhotos(
            id: user['id'],
            name: user['user_details']['name'],
            email: user['user_details']['email'],
            phone: user['user_details']['phone'],
            location: Location.fromJson(user['user_details']['location']),
            photos: List<String>.from(photos),
          );
        }).toList();
      }
    } catch (e) {
      print('Error fetching users with photos: $e');
    } finally {
      isLoading.value = false;
    }
  }
} 