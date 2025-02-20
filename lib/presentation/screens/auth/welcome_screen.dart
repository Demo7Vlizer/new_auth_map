import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../../widgets/buttons/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              // Logo
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
              const SizedBox(height: 40),
              // Title
              Text(
                'Welcome to Location Tracker',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                'Track and share your location with other users in real-time',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Login Button
              CustomButton(
                text: 'Login',
                onPressed: () => Get.to(() => LoginScreen()),
                backgroundColor: Colors.blue,
              ),
              const SizedBox(height: 16),
              // Register Button
              CustomButton(
                text: 'Register',
                onPressed: () => Get.to(() => RegisterScreen()),
                backgroundColor: Colors.white,
                textColor: Colors.blue,
                borderColor: Colors.blue,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
} 