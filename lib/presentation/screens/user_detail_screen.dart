import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON decoding
import 'package:auth_map/models/user_detail.dart'; // Importing the UserDetail model
import 'package:geocoding/geocoding.dart'; // For geocoding addresses
import 'package:auth_map/presentation/screens/full_image_viewer.dart'; // Importing the image viewer

class UserDetailScreen extends StatelessWidget {
  final String userName; // The name of the user to display details for

  UserDetailScreen({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName), // Display the user's name in the app bar
      ),
      body: FutureBuilder<List<UserDetail>>(
        future: fetchUserDetails(), // Fetch user details asynchronously
        builder: (context, snapshot) {
          // Handle different states of the Future
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Show loading indicator
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}')); // Show error message
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found')); // Show message if no users
          }

          // Filter users to only show the selected user's details
          final users = snapshot.data!.where((user) => user.name == userName).toList();
          
          // Check if the filtered list is empty
          if (users.isEmpty) {
            return const Center(child: Text('No photos found for this user')); // Show message if no photos
          }

          // Build the grid view to display user details
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2, // Responsive columns
                childAspectRatio: 0.75, // Aspect ratio for each card
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              itemCount: users.length, // Number of users to display
              itemBuilder: (context, index) {
                final user = users[index]; // Get the user for this index
                return UserCard(user: user); // Return a UserCard widget for each user
              },
            ),
          );
        },
      ),
    );
  }

  // Function to fetch user details from the API
  Future<List<UserDetail>> fetchUserDetails() async {
    final response = await http.get(Uri.parse(
        'https://67b82d462bddacfb271144b3.mockapi.io/api/v1/userDetails'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body); // Decode the JSON response
      return data.map((user) => UserDetail.fromJson(user)).toList(); // Convert to UserDetail objects
    } else {
      throw Exception('Failed to load user details'); // Handle error
    }
  }
}

// UserCard widget to display individual user details
class UserCard extends StatelessWidget {
  final UserDetail user;

  const UserCard({Key? key, required this.user}) : super(key: key);

  // Function to get the address from latitude and longitude
  Future<String> _getAddress(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      Placemark place = placemarks[0];
      return '${place.locality ?? ''}, ${place.administrativeArea ?? ''}'
          .replaceAll(RegExp(r'^\s*,\s*|\s*,\s*$'), ''); // Clean up the address
    } catch (e) {
      return '${lat.toStringAsFixed(2)}, ${long.toStringAsFixed(2)}'; // Fallback to coordinates
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Rounded corners for the card
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullImageViewer(imageUrl: user.image), // Navigate to image viewer
                    ),
                  );
                },
                child: AspectRatio(
                  aspectRatio: 16 / 12, // Aspect ratio for the image
                  child: Hero(
                    tag: user.image,
                    child: Image.network(
                      user.image,
                      fit: BoxFit.cover, // Cover the entire area
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
                    overflow: TextOverflow.ellipsis, // Handle overflow
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
                          overflow: TextOverflow.ellipsis, // Handle overflow
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
                          overflow: TextOverflow.ellipsis, // Handle overflow
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.blue),
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
                              overflow: TextOverflow.ellipsis, // Handle overflow
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
