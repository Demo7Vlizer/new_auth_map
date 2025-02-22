import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'package:hive/hive.dart';
import 'package:get/get.dart';

class UserService {
  static const String _usersBoxName = 'users';
  static const String baseUrl =
      'https://67b6ba3307ba6e590841767c.mockapi.io/api/v1';

  Future<List<UserModel>> getAllUsers() async {
    try {
      // Try to get from API first
      final response = await http.get(Uri.parse('$baseUrl/users'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final users = data.map((json) => UserModel.fromJson(json)).toList();

        // Cache in Hive
        final box = await Hive.openBox<UserModel>(_usersBoxName);
        await box.clear();
        for (var user in users) {
          await box.put(user.id, user);
        }

        return users;
      }

      // If API fails, get from local storage
      final box = await Hive.openBox<UserModel>(_usersBoxName);
      return box.values.toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  Future<UserModel> createUser(UserModel user) async {
    try {
      print('Creating user with ID: ${user.id}'); // Debug log
      
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': user.id,  // Include ID in the root level
          'user_details': {
            'name': user.name,
            'email': user.email,
            'phone': user.phone,
            'location': user.location.toJson(),
            'image': user.image,
          }
        }),
      );

      print('Create user response: ${response.body}'); // Debug log

      if (response.statusCode == 201) {
        final createdUser = UserModel.fromJson(json.decode(response.body));
        await _cacheUser(createdUser);
        return createdUser;
      }
      throw Exception('Failed to create user');
    } catch (e) {
      print('Error creating user: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
        final response = await http.put(
            Uri.parse('$baseUrl/users/${user.id}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
                'user_details': {
                    'name': user.name,
                    'email': user.email,
                    'phone': user.phone,
                    'location': user.location.toJson(),
                    'image': user.image,
                }
            }),
        );

        print('Update response: ${response.body}');

        if (response.statusCode != 200) {
            throw Exception('Failed to update user: ${response.body}');
        }

        // Update local storage
        final box = await Hive.openBox<UserModel>(_usersBoxName);
        await box.put(user.id, user);
    } catch (e) {
        print('Error updating user: $e');
        throw Exception('Failed to update user: $e');
    }
  }

  Future<UserModel?> getUserByPhone(String phone) async {
    try {
      final users = await getAllUsers();
      return users.firstWhereOrNull((user) => user.phone == phone);
    } catch (e) {
      print('Error getting user by phone: $e');
      return null;
    }
  }

  Future<void> updateUserLocation(String userId, Location location) async {
    try {
      final box = await Hive.openBox<UserModel>(_usersBoxName);
      final user = box.get(userId);
      if (user == null) throw Exception('User not found');

      final updatedUser = user.copyWith(location: location);
      await updateUser(updatedUser);
    } catch (e) {
      print('Error updating location: $e');
      throw Exception('Failed to update location: $e');
    }
  }


  Future<UserModel?> verifyOTP(String phone, String otp) async {
    try {
      if (otp.length == 6) {
        // First try to get the user from API
        final response = await http.get(
          Uri.parse('$baseUrl/users'),
        );

        if (response.statusCode == 200) {
          final List<dynamic> users = json.decode(response.body);
          final existingUser = users.firstWhere(
            (user) => user['user_details']['phone'] == '+91$phone',
            orElse: () => null,
          );

          if (existingUser != null) {
            return UserModel.fromJson(existingUser);
          }
        }

        // If user not found, create new one
        return UserModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'New User',
          email: '',
          phone: '+91$phone',
          location: Location(latitude: 0, longitude: 0),
          image: '',
        );
      }
      return null;
    } catch (e) {
      print('Error verifying OTP: $e');
      return null;
    }
  }

  Future<List<dynamic>> fetchUsers() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      return json.decode(response.body); // Decode the JSON response
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<void> _cacheUser(UserModel user) async {
    final box = await Hive.openBox<UserModel>(_usersBoxName);
    await box.put(user.id, user);
  }
}
