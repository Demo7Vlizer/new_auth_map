import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/map_controller.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are initialized
    final mapController = Get.find<MapController>();
    final authController = Get.find<AuthController>();

    // Check if user is logged in
    if (authController.currentUser.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/welcome');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            return GoogleMap(
              onMapCreated: mapController.onMapCreated,
              initialCameraPosition: CameraPosition(
                target: mapController.currentLocation.value,
                zoom: 15,
              ),
              markers: mapController.markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: mapController.currentMapType.value,
            );
          }),
          // Add your other UI elements here
        ],
      ),
    );
  }
}