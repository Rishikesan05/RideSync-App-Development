import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../widgets/custom_button.dart';

// Step 1: Personal Information & Identity for Bus Operator Registration
class Step1 extends StatelessWidget {
  final VoidCallback onNext;

  const Step1({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark
                      ? Colors.white10
                      : AppColors.primaryNavy.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: isDark ? Colors.white70 : AppColors.primaryNavy,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryOrange,
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(context, 'Full Name', Icons.person_outline),
          const SizedBox(height: 16),
          _buildTextField(context, 'Email Address', Icons.email_outlined),
          const SizedBox(height: 16),
          _buildTextField(context, 'Phone Number', Icons.phone_outlined),
          const SizedBox(height: 32),
          Text(
            'Identity Documents',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildUploadSlot(context, 'NIC (Front Side)'),
          _buildUploadSlot(context, 'NIC (Back Side)'),
          _buildUploadSlot(context, 'Driving License (Front)'),
          _buildUploadSlot(context, 'Driving License (Back)'),
          const SizedBox(height: 40),
          CustomButton(label: 'Continue to Step 2', onPressed: onNext),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryOrange),
        ),
      ),
    );
  }

  Widget _buildUploadSlot(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white12
              : AppColors.textLight.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textLight,
            ),
          ),
          const Icon(Icons.upload_file, color: AppColors.primaryOrange),
        ],
      ),
    );
  }
}
