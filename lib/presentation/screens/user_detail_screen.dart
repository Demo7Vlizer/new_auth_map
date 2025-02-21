import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

          final users = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two cards per row
                childAspectRatio: 0.75, // Adjust the aspect ratio as needed
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 120, // Set a fixed height for the image
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(user.image),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Phone: ${user.phone}'),
            const SizedBox(height: 8),
            Text('Email: ${user.email}'),
          ],
        ),
      ),
    );
  }
}

class UserDetail {
  final String id;
  final String name;
  final String image;
  final String phone;
  final String email;
  final Location location;

  UserDetail({
    required this.id,
    required this.name,
    required this.image,
    required this.phone,
    required this.email,
    required this.location,
  });

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    return UserDetail(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      phone: json['phone'],
      email: json['email'],
      location: Location.fromJson(json['location']),
    );
  }
}

class Location {
  final double latitude;
  final double longitude;

  Location({required this.latitude, required this.longitude});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  } 
}
