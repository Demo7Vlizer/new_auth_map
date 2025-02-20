import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config/app_config.dart';

class ImageService {
  static String get uploadUrl => 
    'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryName}/image/upload';

  Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..fields['upload_preset'] = AppConfig.cloudinaryPreset
        ..fields['cloud_name'] = AppConfig.cloudinaryName
        ..fields['api_key'] = AppConfig.cloudinaryApiKey
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(responseString);
        return jsonData['secure_url'];
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
} 