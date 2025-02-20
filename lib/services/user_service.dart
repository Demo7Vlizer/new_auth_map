import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import '../models/user_model.dart';
import 'package:hive/hive.dart';

class UserService {
  static const String _usersBoxName = 'users';
  static const String baseUrl = 'https://67b6ba3307ba6e590841767c.mockapi.io/api/v1';

  Future<List<UserModel>> getAllUsers() async {
    try {
      // Get users from Hive first
      final box = await Hive.openBox<UserModel>(_usersBoxName);
      List<UserModel> users = box.values.toList();

      // Update storage with fresh data
      try {
        final freshUsers = await _fetchUsersFromAPI();
        if (freshUsers.isNotEmpty) {
          users = freshUsers;
          // Update Hive storage
          await box.clear();
          for (var user in users) {
            await box.put(user.id, user);
          }
        }
      } catch (e) {
        print('Error fetching fresh data: $e');
        // Continue with cached data if API fails
      }

      return users;
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  Future<UserModel> createUser(UserModel user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );
      
      if (response.statusCode == 201) {
        final createdUser = UserModel.fromJson(json.decode(response.body));
        // Cache user
        final box = await Hive.openBox<UserModel>(_usersBoxName);
        await box.put(createdUser.id, createdUser);
        return createdUser;
      }
      throw Exception('Failed to create user');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> updateUserLocation(String userId, Location location) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_details': {
            'location': location.toJson(),
          }
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update location');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      // Update in API
      await _updateUserInAPI(user);
      
      // Update in Hive storage
      final box = await Hive.openBox<UserModel>(_usersBoxName);
      await box.put(user.id, user);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
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

  Future<List<UserModel>> _fetchUsersFromAPI() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UserModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load users');
    } catch (e) {
      print('Error getting users: $e');
      // Return cached users if available
      final box = await Hive.openBox<UserModel>(_usersBoxName);
      return box.values.toList();
    }
  }

  Future<void> _updateUserInAPI(UserModel user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update user');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
} 