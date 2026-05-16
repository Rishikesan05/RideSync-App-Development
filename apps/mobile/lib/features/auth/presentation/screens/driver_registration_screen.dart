import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:ridesync/core/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController(text: '+94');
  final _passC = TextEditingController();
  final _licenseC = TextEditingController();
  final _experienceC = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _passC.dispose();
    _licenseC.dispose();
    _experienceC.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // 1. Create Auth User
      UserCredential cred = await auth.createUserWithEmailAndPassword(
        email: _emailC.text.trim(),
        password: _passC.text.trim(),
      );

      // 2. Create User Doc (role: operator, status: pending)
      await firestore.collection('users').doc(cred.user!.uid).set({
        'role': 'operator',
        'status': 'pending_review',
        'displayName': _nameC.text.trim(),
        'email': _emailC.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Create Operator Profile Doc
      await firestore.collection('operators').doc(cred.user!.uid).set({
        'displayName': _nameC.text.trim(),
        'email': _emailC.text.trim(),
        'phone': _phoneC.text.trim(),
        'licenseNumber': _licenseC.text.trim(),
        'experienceYears': int.tryParse(_experienceC.text.trim()) ?? 0,
        'status': 'pending_review',
        'registrationDate': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // Show success and go back to role selection
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration submitted! We will review your application.')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (r) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blue = const Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Operator Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : AppColors.textDark,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _handleRegistration();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_currentStep == 2 ? 'Submit' : 'Continue', style: const TextStyle(color: Colors.white)),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Personal'),
            isActive: _currentStep >= 0,
            content: Form(
              key: _currentStep == 0 ? _formKey : null,
              child: Column(
                children: [
                  _formField(isDark, 'Full Name', Icons.person_outline, _nameC),
                  const SizedBox(height: 16),
                  _formField(isDark, 'Gmail Address', Icons.email_outlined, _emailC),
                  const SizedBox(height: 16),
                  _formField(isDark, 'Phone Number', Icons.phone_outlined, _phoneC),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Account'),
            isActive: _currentStep >= 1,
            content: Column(
              children: [
                _formField(isDark, 'Password', Icons.lock_outline, _passC, isPassword: true),
                const SizedBox(height: 16),
                const Text('Choose a strong password for your operator portal.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Step(
            title: const Text('License'),
            isActive: _currentStep >= 2,
            content: Column(
              children: [
                _formField(isDark, 'License Number', Icons.badge_outlined, _licenseC),
                const SizedBox(height: 16),
                _formField(isDark, 'Years of Experience', Icons.history_edu_outlined, _experienceC, keyboardType: TextInputType.number),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formField(bool isDark, String label, IconData icon, TextEditingController controller, {bool isPassword = false, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
