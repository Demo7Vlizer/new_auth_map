import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../widgets/inputs/phone_input.dart';
import '../../widgets/buttons/custom_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authController = Get.find<AuthController>();
  final RxBool _codeSent = false.obs;
  final RxBool _isValidNumber = false.obs;

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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    !_codeSent.value ? 'Welcome Back!' : 'Enter OTP',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    !_codeSent.value
                        ? 'Login with your registered phone number'
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
                    // New user prompt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New user? ',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        TextButton(
                          onPressed: () => Get.off(() => RegisterScreen()),
                          child: const Text(
                            'Register here',
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
                  Obx(() => CustomButton(
                    text: !_codeSent.value ? 'Send OTP' : 'Verify',
                    onPressed: _authController.isLoading.value
                        ? null
                        : () async {
                            if (!_codeSent.value) {
                              final userExists = await _authController.checkUserExists(_phoneController.text);
                              if (!userExists) {
                                Get.snackbar(
                                  'Account Not Found',
                                  'This number is not registered. Would you like to create a new account?',
                                  backgroundColor: Colors.blue.shade50,
                                  duration: const Duration(seconds: 5),
                                  mainButton: TextButton(
                                    onPressed: () {
                                      Get.back(); // Close snackbar
                                      Get.off(() => RegisterScreen());
                                    },
                                    child: const Text('Register'),
                                  ),
                                );
                                return;
                              }
                              if (await _authController.sendLoginOTP(_phoneController.text)) {
                                _codeSent.value = true;
                              }
                            } else {
                              if (await _authController.verifyLoginOTP(
                                _phoneController.text,
                                _otpController.text,
                              )) {
                                Get.offAllNamed('/map');
                              }
                            }
                          },
                    isLoading: _authController.isLoading.value,
                  )),
                  if (_codeSent.value) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          _otpController.clear();
                          if (await _authController.sendLoginOTP(_phoneController.text)) {
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
            }),
          ),
        ),
      ),
    );
  }
} 