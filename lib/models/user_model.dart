import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String phone;

  @HiveField(4)
  final Location location;

  @HiveField(5)
  final String? image;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    this.image,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    print('Parsing user JSON: $json'); // Debug log
    return UserModel(
      id: json['id']?.toString() ?? '',  // Ensure ID is properly extracted
      name: json['user_details']['name'] ?? '',
      email: json['user_details']['email'] ?? '',
      phone: json['user_details']['phone'] ?? '',
      location: Location.fromJson(json['user_details']['location'] ?? {}),
      image: json['user_details']['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_details': {
        'name': name,
        'email': email,
        'phone': phone,
        'image': image,
        'location': location.toJson(),
      }
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    Location? location,
    String? image,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      image: image ?? this.image,
    );
  }
}

@HiveType(typeId: 1)
class Location {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  Location({
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
