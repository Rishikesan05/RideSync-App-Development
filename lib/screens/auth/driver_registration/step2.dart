import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../widgets/custom_button.dart';

// Step 2: Official Certifications & Vehicle details for Bus Operator Registration
class Step2 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step2({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Professional Credentials',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoBox(
            context,
            'Ensure all uploaded certificates are valid and clearly visible for verification.',
          ),
          const SizedBox(height: 24),
          _buildTextField(
            context,
            'Heavy Vehicle License Number',
            Icons.badge_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            context,
            'Year of Issuance',
            Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 32),
          Text(
            'Certificates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildUploadButton(context, 'Medical Fitness Certificate'),
          _buildUploadButton(context, 'Official Training Certificate'),
          const SizedBox(height: 48),
          CustomButton(label: 'Enter Final Step', onPressed: onNext),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onBack,
            child: Center(
              child: Text(
                'Back to Personal Info',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textLight,
                ),
              ),
            ),
          ),
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

  Widget _buildUploadButton(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.cloud_upload_outlined),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          foregroundColor: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.primaryNavy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : AppColors.primaryNavy.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: isDark ? Colors.white70 : AppColors.primaryNavy,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
