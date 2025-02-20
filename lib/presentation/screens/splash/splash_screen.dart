import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final authController = Get.find<AuthController>();
      
      // Initialize session service if not already initialized
      if (!authController.sessionService.isInitialized) {
        await authController.sessionService.init();
      }

      // Add small delay for splash screen
      await Future.delayed(const Duration(seconds: 2));

      // Check if session is valid
      if (authController.sessionService.isSessionValid()) {
        final savedUser = authController.sessionService.getCurrentUser();
        if (savedUser != null) {
          // Update current user in auth controller
          authController.currentUser.value = savedUser;
          
          // Update user's location silently
          try {
            final location = await authController.getCurrentLocation();
            await authController.updateUserProfile(
              name: savedUser.name,
              email: savedUser.email,
              location: location,
            );
          } catch (e) {
            print('Error updating location: $e');
            // Continue even if location update fails
          }
          
          Get.offAllNamed('/map');
          return;
        }
      }
      
      // No valid session found
      Get.offAllNamed('/welcome');
    } catch (e) {
      print('Error initializing app: $e');
      Get.offAllNamed('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                size: 60,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            Text(
              'Location Tracker',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 48),
            // Loading Indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
            ),
          ],
        ),
      ),
    );
  }
} 