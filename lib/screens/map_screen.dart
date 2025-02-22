// ignore_for_file: prefer_const_constructors, unused_element

import 'package:auth_map/presentation/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/map_controller.dart';
import '../controllers/auth_controller.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  Widget _buildCompass(MapController mapController) {
    return Positioned(
      right: 16,
      top: 100,
      child: Obx(() {
        final rotation = mapController.bearing.value * (3.14159 / 180) * -1;
        return Transform.rotate(
          angle: rotation,
          child: SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: const [
                Positioned(
                  top: 0,
                  child: Text(
                    'N',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapController = Get.put(MapController());
    final authController = Get.find<AuthController>();

    // Get arguments if passed
    final Map<String, dynamic>? args = Get.arguments;
    if (args != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.focusOnUser(
          args['focusUser'],
          args['initialLocation'],
          args['zoomLevel'],
        );
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map
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
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              padding: EdgeInsets.only(top: 100, left: 15),
              mapType: mapController.currentMapType.value,
            );
          }),

          // Top Bar
          SafeArea(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'User Locations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  _buildActionButton(
                    icon: Icons.person,
                    onTap: () => Get.to(() => ProfileScreen()),
                  ),
                  _buildActionButton(
                    icon: Icons.people,
                    onTap: () => Get.toNamed('/users'),
                  ),
                  _buildActionButton(
                    icon: Icons.refresh,
                    onTap: () => mapController.loadUsers(),
                  ),
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'map_type',
                        child: ListTile(
                          leading: Icon(Icons.map, color: Colors.blue.shade700),
                          title: Text(
                            'Map Type',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: ListTile(
                          leading:
                              Icon(Icons.logout, color: Colors.red.shade400),
                          title: Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      switch (value) {
                        case 'map_type':
                          _showMapTypeModal(context, mapController);
                          break;
                        case 'logout':
                          final confirm = await _showLogoutDialog();
                          if (confirm == true) {
                            await authController.logout();
                          }
                          break;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Map Controls
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              children: [
                _buildFloatingButton(
                  icon: Icons.my_location,
                  onTap: () => mapController.goToMyLocation(),
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildZoomButton(
                        icon: Icons.add,
                        onTap: () => mapController.zoomIn(),
                      ),
                      Container(
                        height: 1,
                        width: 20,
                        color: Colors.grey.shade200,
                      ),
                      _buildZoomButton(
                        icon: Icons.remove,
                        onTap: () => mapController.zoomOut(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tracking Indicator
          Positioned(
            top: 120,
            right: 16,
            child: Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: mapController.isTrackingEnabled.value 
                    ? Colors.green.withOpacity(0.8) 
                    : Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mapController.isTrackingEnabled.value 
                        ? Icons.location_on 
                        : Icons.location_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    mapController.isTrackingEnabled.value 
                        ? 'Tracking On' 
                        : 'Tracking Off',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )),
          ),

          Obx(() => SwitchListTile(
            title: Text('Enable Location Tracking'),
            value: mapController.isTrackingEnabled.value,
            onChanged: (value) {
              if (value) {
                mapController.startLocationTracking();
              } else {
                mapController.stopLocationTracking();
              }
            },
          )),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 20,
            color: Colors.blue.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: EdgeInsets.all(12),
            child: Icon(
              icon,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: EdgeInsets.all(8),
          child: Icon(
            icon,
            color: Colors.blue.shade700,
          ),
        ),
      ),
    );
  }

  void _showMapTypeModal(BuildContext context, MapController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Map Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildMapTypeOption(
              icon: Icons.map_outlined,
              title: 'Normal',
              onTap: () {
                controller.updateMapType(MapType.normal);
                Get.back();
              },
            ),
            _buildMapTypeOption(
              icon: Icons.satellite_outlined,
              title: 'Satellite',
              onTap: () {
                controller.updateMapType(MapType.satellite);
                Get.back();
              },
            ),
            _buildMapTypeOption(
              icon: Icons.terrain_outlined,
              title: 'Terrain',
              onTap: () {
                controller.updateMapType(MapType.terrain);
                Get.back();
              },
            ),
            _buildMapTypeOption(
              icon: Icons.layers_outlined,
              title: 'Hybrid',
              onTap: () {
                controller.updateMapType(MapType.hybrid);
                Get.back();
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue.shade700),
              SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showLogoutDialog() {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade400,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
