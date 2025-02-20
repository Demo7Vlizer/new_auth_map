import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'map_screen.dart';

class AuthScreen extends StatelessWidget {
  AuthScreen({super.key});

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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Obx(() {
              if (_authController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  // Logo or Image
                  Center(
                    child: Container(
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
                  ),
                  const SizedBox(height: 40),
                  // Title
                  Text(
                    !_codeSent.value ? 'Enter Phone Number' : 'Enter OTP',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    !_codeSent.value
                        ? 'We will send you a one-time password'
                        : 'Please enter the verification code sent to +91 ${_phoneController.text}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (!_codeSent.value) ...[
                    // Phone Number Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Country Code
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            child: Text(
                              '+91',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.grey.shade300,
                          ),
                          // Phone Number Field
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              onChanged: _validatePhone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                hintText: 'Phone Number',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // OTP Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          hintText: 'Enter 6-digit OTP',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: !_codeSent.value
                          ? (_isValidNumber.value
                              ? () async {
                                  if (await _authController
                                      .verifyPhone(_phoneController.text)) {
                                    _codeSent.value = true;
                                  }
                                }
                              : null)
                          : () async {
                              if (await _authController.verifyOTP(
                                _phoneController.text,
                                _otpController.text,
                              )) {
                                Get.off(() => const MapScreen());
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        !_codeSent.value ? 'Send OTP' : 'Verify',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (_codeSent.value) ...[
                    const SizedBox(height: 24),
                    // Resend OTP
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          _otpController.clear();
                          if (await _authController
                              .verifyPhone(_phoneController.text)) {
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