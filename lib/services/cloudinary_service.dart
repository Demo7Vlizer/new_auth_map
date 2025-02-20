import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../core/config/app_config.dart';

class CloudinaryService {
  late final CloudinaryPublic cloudinary;

  CloudinaryService() {
    _initCloudinary();
  }

  void _initCloudinary() {
    final cloudName = AppConfig.cloudinaryName;
    final uploadPreset = AppConfig.cloudinaryPreset;
    
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      print('Cloudinary Error: Missing credentials');
      print('cloudName: $cloudName');
      print('uploadPreset: $uploadPreset');
      throw Exception('Cloudinary credentials not configured. Please check your .env file.');
    }
    
    cloudinary = CloudinaryPublic(
      cloudName,
      uploadPreset,
      cache: false,
    );
  }

  Future<String> uploadImage(File image) async {
    try {
      // Validate file exists and is readable
      if (!await image.exists()) {
        throw Exception('Image file does not exist');
      }

      // Add timeout to prevent hanging
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          folder: AppConfig.cloudinaryFolder,
          resourceType: CloudinaryResourceType.Image,
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Upload timed out'),
      );
      
      if (response.secureUrl.isEmpty) {
        throw Exception('Empty URL received from Cloudinary');
      }
      
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }
} 