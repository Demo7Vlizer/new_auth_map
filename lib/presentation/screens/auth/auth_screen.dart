import 'package:auth_map/controllers/auth_controller.dart';
import 'package:auth_map/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../widgets/inputs/phone_input.dart';
import '../../widgets/buttons/custom_button.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

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
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Obx(() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildLogo(),
                  const SizedBox(height: 40),
                  Text(
                    !_codeSent.value ? 'Enter Phone Number' : 'Enter OTP',
                    style: AppTextStyles.heading,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    !_codeSent.value
                        ? 'We will send you a one-time password'
                        : 'Please enter the verification code sent to +91 ${_phoneController.text}',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 40),
                  if (!_codeSent.value)
                    PhoneInput(
                      controller: _phoneController,
                      onChanged: _validatePhone,
                    )
                  else
                    _buildOtpInput(),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: !_codeSent.value ? 'Send OTP' : 'Verify',
                    onPressed: _buildButtonCallback(),
                    isLoading: _authController.isLoading.value,
                  ),
                  if (_codeSent.value) _buildResendButton(),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.location_on,
          size: 60,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          hintText: 'Enter 6-digit OTP',
          hintStyle: TextStyle(color: AppColors.grey400),
        ),
      ),
    );
  }

  VoidCallback? _buildButtonCallback() {
    if (!_codeSent.value) {
      return _isValidNumber.value
          ? () async {
              if (await _authController.verifyPhone(_phoneController.text)) {
                _codeSent.value = true;
              }
            }
          : null;
    }
    return () async {
      if (await _authController.verifyOTP(
        _phoneController.text,
        _otpController.text,
      )) {
        Get.off(() => const MapScreen());
      }
    };
  }

  Widget _buildResendButton() {
    return Center(
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
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 