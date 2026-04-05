import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/modules/operator/providers/registration_provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/custom_button.dart';

/// Step 1: Personal Information for Bus Operator Registration
/// Collects: Name, Gmail, Sri Lankan phone, password
class Step1 extends StatefulWidget {
  final VoidCallback onNext;

  const Step1({super.key, required this.onNext});

  @override
  State<Step1> createState() => _Step1State();
}

class _Step1State extends State<Step1> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController phoneC = TextEditingController(text: '+94');
  final TextEditingController passC = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final p = Provider.of<RegistrationProvider>(context, listen: false);
    if (p.name.isNotEmpty) nameC.text = p.name;
    if (p.email.isNotEmpty) emailC.text = p.email;
    if (p.phone.isNotEmpty) phoneC.text = p.phone;
    if (p.password.isNotEmpty) passC.text = p.password;
  }

  bool _isGmail(String e) => e.toLowerCase().endsWith('@gmail.com');
  bool _isValidSLPhone(String p) => RegExp(r'^\+94\d{9}$').hasMatch(p);

  void _handleNext() {
    if (!_formKey.currentState!.validate()) return;
    Provider.of<RegistrationProvider>(context, listen: false).updateStep1(
      n: nameC.text.trim(),
      e: emailC.text.trim(),
      p: phoneC.text.trim(),
      pass: passC.text.trim(),
    );
    widget.onNext();
  }

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    phoneC.dispose();
    passC.dispose();
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
                _stepLine(isDark),
                _stepDot(2, false),
                _stepLine(isDark),
                _stepDot(3, false),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Personal Details',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tell us about yourself to get started',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 28),

            // Avatar placeholder
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.person, size: 40, color: AppColors.primaryOrange),
              ),
            ),
            const SizedBox(height: 28),

            _buildField(isDark, 'Full Name', Icons.person_outline, nameC,
                validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name is required';
              return null;
            }),
            const SizedBox(height: 16),
            _buildField(isDark, 'Gmail Address', Icons.email_outlined, emailC,
                keyboardType: TextInputType.emailAddress, validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!_isGmail(v.trim())) return 'Only Gmail addresses allowed';
              return null;
            }),
            const SizedBox(height: 16),
            _buildField(isDark, 'Phone (+94XXXXXXXXX)', Icons.phone_outlined, phoneC,
                keyboardType: TextInputType.phone, validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Phone is required';
              if (!_isValidSLPhone(v.trim())) {
                return 'Enter a valid Sri Lankan number';
              }
              return null;
            }),
            const SizedBox(height: 16),
            _buildField(isDark, 'Password', Icons.lock_outline, passC,
                isPassword: true, validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            }),
            const SizedBox(height: 40),

            CustomButton(label: 'Continue to Step 2', onPressed: _handleNext),
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
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      obscureText: isPassword ? _obscure : false,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                    color: isDark ? Colors.white54 : Colors.grey),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
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

  Widget _stepLine(bool isDark) {
    return Expanded(
      child: Container(
        height: 2,
        color: isDark ? Colors.white12 : Colors.grey.shade300,
      ),
    );
  }
}
