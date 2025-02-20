import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserListController extends GetxController {
  final UserService _userService = UserService();
  final RxBool isLoading = false.obs;
  final RxList<UserModel> users = <UserModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      users.value = await _userService.getAllUsers();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load users: $e',
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshUsers() async {
    await loadUsers();
  }

  void showUserOnMap(UserModel user) {
    Get.toNamed('/map', arguments: {
      'focusUser': user,
      'initialLocation': LatLng(
        user.location.latitude,
        user.location.longitude,
      ),
      'zoomLevel': 15.0,
    });
  }
} 