import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class PhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const PhoneInput({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
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
                color: AppColors.grey700,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: AppColors.grey200,
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 10,
              onChanged: onChanged,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: 'Phone Number',
                hintStyle: TextStyle(
                  color: AppColors.grey400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 