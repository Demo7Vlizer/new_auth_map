// ignore_for_file: use_key_in_widget_constructors

import 'package:auth_map/models/user_with_photos.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_with_photos_controller.dart';

class UserWithPhotosScreen extends StatelessWidget {
  final UserWithPhotosController controller =
      Get.put(UserWithPhotosController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users with Photos'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.usersWithPhotos.isEmpty) {
          return const Center(child: Text('No users found'));
        }

        return ListView.builder(
          itemCount: controller.usersWithPhotos.length,
          itemBuilder: (context, index) {
            final user = controller.usersWithPhotos[index];
            return UserCard(user: user);
          },
        );
      }),
    );
  }
}

class UserCard extends StatelessWidget {
  final UserWithPhotos user;

  const UserCard({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Email: ${user.email}'),
            Text('Phone: ${user.phone}'),
            const SizedBox(height: 8),
            Text(
                'Location: Lat: ${user.location.latitude}, Long: ${user.location.longitude}'),
            const SizedBox(height: 10),
            const Text('Uploaded Photos:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: user.photos.length,
                itemBuilder: (context, photoIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipOval(
                      child: Image.network(
                        user.photos[photoIndex],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
