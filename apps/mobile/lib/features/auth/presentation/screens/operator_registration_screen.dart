import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:ridesync/core/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OperatorRegistrationScreen extends StatefulWidget {
  const OperatorRegistrationScreen({super.key});

  @override
  State<OperatorRegistrationScreen> createState() => _OperatorRegistrationScreenState();
}

class _OperatorRegistrationScreenState extends State<OperatorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController(text: '+94');
  final _passC = TextEditingController();
  final _operatorIdC = TextEditingController();
  final _nicC = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _passC.dispose();
    _operatorIdC.dispose();
    _nicC.dispose();
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
        'operatorId': _operatorIdC.text.trim(),
        'displayName': _nameC.text.trim(),
        'email': _emailC.text.trim(),
        'phone': _phoneC.text.trim(),
        'nic': _nicC.text.trim(),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _formField(isDark, 'Full Name', Icons.person_outline, _nameC, hintText: 'e.g. Nimal Perera'),
                  const SizedBox(height: 16),
                  _formField(isDark, 'Gmail Address', Icons.email_outlined, _emailC, hintText: 'e.g. nimal@gmail.com'),
                  const SizedBox(height: 16),
                  _formField(isDark, 'Phone Number', Icons.phone_outlined, _phoneC, hintText: 'e.g. +94771234567'),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Account'),
            isActive: _currentStep >= 1,
            content: Column(
              children: [
                _formField(isDark, 'Password', Icons.lock_outline, _passC, isPassword: true, hintText: 'Min 8 chars, 1 uppercase'),
                const SizedBox(height: 16),
                const Text('Choose a strong password for your operator portal.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Step(
            title: const Text('Credentials'),
            isActive: _currentStep >= 2,
            content: Column(
              children: [
                _formField(isDark, 'Operator ID', Icons.badge, _operatorIdC, hintText: 'e.g. RSOP26-001'),
                const SizedBox(height: 16),
                _formField(isDark, 'National Identity Card (NIC)', Icons.credit_card_outlined, _nicC, hintText: 'e.g. 199912345678 or 991234567V'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formField(bool isDark, String label, IconData icon, TextEditingController controller, {bool isPassword = false, TextInputType keyboardType = TextInputType.text, String? hintText}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700),
        hintText: hintText,
        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400, fontWeight: FontWeight.normal),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(icon, color: isDark ? Colors.white54 : Colors.grey.shade500),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
        ),
      ),
    );
  }
}
