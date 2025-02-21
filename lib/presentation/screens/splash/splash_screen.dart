import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/services/session_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Add artificial delay for splash screen
      await Future.delayed(const Duration(seconds: 2));

      // Check if there's a valid session
      final hasValidSession = await _sessionService.isSessionValid();
      
      if (hasValidSession) {
        final savedUser = await _sessionService.getCurrentUser();
        if (savedUser != null) {
          final authController = Get.find<AuthController>();
          
          // Restore user session
          authController.currentUser.value = savedUser;
          
          // Navigate to map screen
          Get.offAllNamed('/map');
          return;
        }
      }

      // No valid session, go to welcome screen
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
