import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Update with your project name Update with your project name
import 'package:auth_map/models/user_detail.dart'; // Add this import
import 'package:geocoding/geocoding.dart';
import 'package:auth_map/presentation/screens/full_image_viewer.dart';
import 'full_image_viewer.dart'; // Add this import

class UserDetailScreen extends StatelessWidget {
  final String userName;

  UserDetailScreen({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
      ),
      body: FutureBuilder<List<UserDetail>>(
        future: fetchUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          // Filter users to only show the selected user's details
          final users = snapshot.data!.where((user) => user.name == userName).toList();
          
          if (users.isEmpty) {
            return const Center(child: Text('No photos found for this user'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return UserCard(user: user);
              },
            ),
          );
        },
      ),
    );
  }

  Future<List<UserDetail>> fetchUserDetails() async {
    final response = await http.get(Uri.parse(
        'https://67b82d462bddacfb271144b3.mockapi.io/api/v1/userDetails'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((user) => UserDetail.fromJson(user)).toList();
    } else {
      throw Exception('Failed to load user details');
    }
  }
}

class UserCard extends StatelessWidget {
  final UserDetail user;

  const UserCard({Key? key, required this.user}) : super(key: key);

  Future<String> _getAddress(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      Placemark place = placemarks[0];
      return '${place.locality ?? ''}, ${place.administrativeArea ?? ''}'
          .replaceAll(RegExp(r'^\s*,\s*|\s*,\s*$'), '');
    } catch (e) {
      return '${lat.toStringAsFixed(2)}, ${long.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FullImageViewer(imageUrl: user.image),
                    ),
                  );
                },
                child: AspectRatio(
                  aspectRatio: 16 / 12,
                  child: Hero(
                    tag: user.image,
                    child: Image.network(
                      user.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          user.phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: FutureBuilder<String>(
                          future: _getAddress(
                            user.location.latitude,
                            user.location.longitude,
                          ),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? 'Loading address...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
