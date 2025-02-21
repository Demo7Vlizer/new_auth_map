import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/map_controller.dart';
import '../../../models/user_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../upload_details_screen.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mapController = Get.find<MapController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Users'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue.shade700),
            onPressed: mapController.loadUsers,
          ),
        ],
      ),
      body: Obx(() {
        if (mapController.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.blue.shade400,
            ),
          );
        }

        if (mapController.users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: mapController.loadUsers,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mapController.users.length,
            itemBuilder: (context, index) {
              final user = mapController.users[index];
              return _buildUserCard(user, mapController);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => UploadDetailsScreen());
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildUserCard(UserModel user, MapController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Get.back();
          controller.focusOnUser(
            user,
            LatLng(user.location.latitude, user.location.longitude),
            15.0,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                  image: user.image != null
                      ? DecorationImage(
                          image: NetworkImage(user.image!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: user.image == null
                    ? Icon(
                        Icons.person,
                        color: Colors.blue.shade200,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isEmpty ? 'New User' : user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Lat: ${user.location.latitude.toStringAsFixed(4)}, Long: ${user.location.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
