import 'package:auth_map/presentation/screens/user_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewPageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: FutureBuilder<List<UserDetail>>(
        future: fetchUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No users found'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: user.image != null ? NetworkImage(user.image!) : null,
                    child: user.image == null ? Icon(Icons.person, color: Colors.blue.shade300) : null,
                  ),
                  title: Text(user.name),
                  subtitle: Text('Lat: ${user.location.latitude}, Long: ${user.location.longitude}'),
                  onTap: () {
                    Get.to(() => UserDetailScreen(userName: user.name));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<UserDetail>> fetchUserDetails() async {
    final response = await http.get(Uri.parse('https://67b6ba3307ba6e590841767c.mockapi.io/api/v1/users'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => UserDetail.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user details');
    }
  }
}

class UserDetail {
  final String id;
  final String name;
  final String? image;
  final Location location;

  UserDetail({
    required this.id, 
    required this.name, 
    this.image,
    required this.location
  });

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    try {
      final userDetails = json['user_details'] ?? {};
      return UserDetail(
        id: json['id']?.toString() ?? '',
        name: userDetails['name']?.toString() ?? 'New User',
        image: userDetails['image']?.toString(),
        location: Location.fromJson(userDetails['location'] ?? {'latitude': 0.0, 'longitude': 0.0}),
      );
    } catch (e) {
      print('Error parsing UserDetail: $e');
      return UserDetail(
        id: '',
        name: 'Unknown User',
        location: Location(latitude: 0.0, longitude: 0.0),
      );
    }
  }
}

class Location {
  final double latitude;
  final double longitude;

  Location({required this.latitude, required this.longitude});

  factory Location.fromJson(Map<String, dynamic> json) {
    try {
      return Location(
        latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
        longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      );
    } catch (e) {
      print('Error parsing Location: $e');
      return Location(latitude: 0.0, longitude: 0.0);
    }
  }
}
