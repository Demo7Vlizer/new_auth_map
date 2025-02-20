import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../widgets/inputs/phone_input.dart';
import '../../widgets/buttons/custom_button.dart';
import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _authController = Get.find<AuthController>();
  final RxBool _codeSent = false.obs;
  final RxBool _isValidNumber = false.obs;
  final RxBool _showProfileSetup = false.obs;

  void _validatePhone(String value) {
    _isValidNumber.value = value.length == 10 && int.tryParse(value) != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade800),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Obx(() {
              if (_showProfileSetup.value) {
                return _buildProfileSetup();
              }
              return _buildPhoneVerification();
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          !_codeSent.value ? 'Create Account' : 'Enter OTP',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          !_codeSent.value
              ? 'Enter your phone number to get started'
              : 'Please enter the verification code sent to +91 ${_phoneController.text}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 40),
        if (!_codeSent.value) ...[
          PhoneInput(
            controller: _phoneController,
            onChanged: _validatePhone,
          ),
          const SizedBox(height: 16),
          // Existing user prompt
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              TextButton(
                onPressed: () => Get.off(() => LoginScreen()),
                child: const Text(
                  'Login here',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ] else
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: 'Enter 6-digit OTP',
                hintStyle: TextStyle(color: Colors.grey.shade400),
              ),
            ),
          ),
        const SizedBox(height: 24),
        CustomButton(
          text: !_codeSent.value ? 'Send OTP' : 'Verify',
          onPressed: _authController.isLoading.value
              ? null
              : () async {
                  if (!_codeSent.value) {
                    final userExists = await _authController.checkUserExists(_phoneController.text);
                    if (userExists) {
                      Get.snackbar(
                        'Account Exists',
                        'This number is already registered. Please login instead.',
                        backgroundColor: Colors.blue.shade50,
                        duration: const Duration(seconds: 5),
                        mainButton: TextButton(
                          onPressed: () {
                            Get.back(); // Close snackbar
                            Get.off(() => LoginScreen());
                          },
                          child: const Text('Login'),
                        ),
                      );
                      return;
                    }
                    if (await _authController.verifyPhone(_phoneController.text)) {
                      _codeSent.value = true;
                    }
                  } else {
                    if (await _authController.verifyOTP(
                      _phoneController.text,
                      _otpController.text,
                    )) {
                      _showProfileSetup.value = true;
                    }
                  }
                },
          isLoading: _authController.isLoading.value,
        ),
        if (_codeSent.value) ...[
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () async {
                _otpController.clear();
                if (await _authController.verifyPhone(_phoneController.text)) {
                  Get.snackbar(
                    'Success',
                    'OTP resent successfully',
                    backgroundColor: Colors.green.shade100,
                  );
                }
              },
              child: Text(
                'Resend OTP',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileSetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Please provide your details to complete registration',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 40),
        // Name Input
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade400),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Email Input
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter your email',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade400),
            ),
          ),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Complete Registration',
          onPressed: () async {
            if (_nameController.text.isEmpty) {
              Get.snackbar(
                'Error',
                'Please enter your name',
                backgroundColor: Colors.red.shade100,
              );
              return;
            }
            
            await _authController.updateUserProfile(
              name: _nameController.text,
              email: _emailController.text,
              location: await _authController.getCurrentLocation(),
            );
            
            Get.offAllNamed('/map');
          },
        ),
      ],
    );
  }
} 