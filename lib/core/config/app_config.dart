import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

class AppConfig {
  static String get cloudinaryName => 
      dotenv.dotenv.env['CLOUDINARY_NAME'] ?? '';
      
  static String get cloudinaryPreset => 
      dotenv.dotenv.env['CLOUDINARY_PRESET'] ?? '';
      
  static String get cloudinaryApiKey => 
      dotenv.dotenv.env['CLOUDINARY_API_KEY'] ?? '';
      
  static String get cloudinaryApiSecret => 
      dotenv.dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
      
  static const cloudinaryFolder = 'auth_map_profiles';
} 