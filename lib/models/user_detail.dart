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