class UserWithPhotos {
  final String id;
  final String name;
  final String email;
  final String phone;
  final Location location;
  final List<String> photos;

  UserWithPhotos({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.photos,
  });

  factory UserWithPhotos.fromJson(Map<String, dynamic> json) {
    return UserWithPhotos(
      id: json['id'],
      name: json['user_details']['name'],
      email: json['user_details']['email'],
      phone: json['user_details']['phone'],
      location: Location.fromJson(json['user_details']['location']),
      photos: List<String>.from(json['photos'] ?? []),
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