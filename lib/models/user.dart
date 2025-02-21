
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final Map<String, dynamic>? location;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      location: json['location'],
    );
  }
} 