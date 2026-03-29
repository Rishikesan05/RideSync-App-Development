import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/modules/operator/providers/registration_provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/custom_button.dart';

/// Step 2: Bus/Company Details for Operator Registration
/// Collects: Heavy vehicle license, year, bus route info
class Step2 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step2({super.key, required this.onNext, required this.onBack});

  @override
  State<Step2> createState() => _Step2State();
}

class _Step2State extends State<Step2> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController hvController = TextEditingController();
  final TextEditingController yearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = Provider.of<RegistrationProvider>(context, listen: false);
    hvController.text = p.heavyVehicleLicense;
    yearController.text = p.yearOfIssuance;
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) return;
    Provider.of<RegistrationProvider>(context, listen: false).updateStep2(
      hv: hvController.text.trim(),
      year: yearController.text.trim(),
    );
    widget.onNext();
  }

  @override
  void dispose() {
    hvController.dispose();
    yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.padding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Row(
              children: [
                _stepDot(1, true),
                _stepLine(isDark, true),
                _stepDot(2, true),
                _stepLine(isDark, false),
                _stepDot(3, false),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Professional Credentials',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your vehicle license details',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 28),

            // Info box
            Container(
              padding: const EdgeInsets.all(14),
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
                  Icon(Icons.info_outline,
                      color: isDark ? Colors.white70 : AppColors.primaryNavy),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ensure your license details are accurate for verification.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : AppColors.primaryNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _buildField(
              isDark,
              'Heavy Vehicle License Number',
              Icons.badge_outlined,
              hvController,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'License number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildField(
              isDark,
              'Year of Issuance',
              Icons.calendar_today_outlined,
              yearController,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Year is required';
                final year = int.tryParse(v.trim());
                if (year == null || year < 1990 || year > 2026) {
                  return 'Enter a valid year (1990-2026)';
                }
                return null;
              },
            ),
            const SizedBox(height: 48),

            CustomButton(label: 'Continue to Final Step', onPressed: _handleNext),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: widget.onBack,
                child: Text(
                  '← Back to Personal Info',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    bool isDark,
    String label,
    IconData icon,
    TextEditingController c, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryOrange),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _stepDot(int step, bool active) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? AppColors.primaryOrange : Colors.transparent,
        border: Border.all(
          color: active ? AppColors.primaryOrange : Colors.grey,
          width: 2,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: active ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _stepLine(bool isDark, bool complete) {
    return Expanded(
      child: Container(
        height: 2,
        color: complete ? AppColors.primaryOrange : (isDark ? Colors.white12 : Colors.grey.shade300),
      ),
    );
  }
}
