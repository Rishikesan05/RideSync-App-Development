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

  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController(text: '+94');
  final _passC = TextEditingController();
  final _operatorIdC = TextEditingController();
  final _nicC = TextEditingController();

  // One FormKey per step so we can validate each step independently
  final _step0Key = GlobalKey<FormState>();
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePass = false;

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

  /// Returns the FormKey for the currently active step.
  GlobalKey<FormState> get _currentStepKey {
    switch (_currentStep) {
      case 0: return _step0Key;
      case 1: return _step1Key;
      default: return _step2Key;
    }
  }

  Future<void> _handleRegistration() async {
    // Validate the final step before submitting
    if (!_step2Key.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // 1. Create Auth User
      UserCredential cred = await auth.createUserWithEmailAndPassword(
        email: _emailC.text.trim(),
        password: _passC.text.trim(),
      );

      // 2. Create User Doc (role: operator, status: pending_review)
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

      // NOTE: We intentionally do NOT sign out here.
      // AuthWrapper reads status from Firestore — since both docs are now written
      // with status:'pending_review', it will automatically show OperatorPendingScreen.
      // Calling auth.signOut() here triggers the authStateChanges stream multiple
      // times causing repeated rebuilds and navigation conflicts.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration submitted! We will review your application within 24–48 hours.')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/operator-pending', (r) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = 'Registration failed';
        if (e.code == 'email-already-in-use') msg = 'An account with this email already exists. Try signing in.';
        if (e.code == 'weak-password') msg = 'Password is too weak. Use at least 8 characters with 1 uppercase.';
        if (e.code == 'invalid-email') msg = 'The email address is not valid.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Custom Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 30, left: 24, right: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryOrange, Colors.orange.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(color: AppColors.primaryOrange.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Operator Portal', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                      SizedBox(height: 4),
                      Text('Registration', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.directions_bus_filled, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryOrange, // Stepper colors
                ),
              ),
              child: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          // Validate the CURRENT step only before advancing
          if (!_currentStepKey.currentState!.validate()) return;
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
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryOrange, Colors.orange.shade700],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: AppColors.primaryOrange.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_currentStep == 2 ? 'Submit Registration' : 'Continue', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : AppColors.textLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              key: _step0Key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _formField(isDark, 'Full Name', Icons.person_outline, _nameC, hintText: 'e.g. Nimal Perera', validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your full name' : null),
                  const SizedBox(height: 16),
                  _formField(isDark, 'Gmail Address', Icons.email_outlined, _emailC, hintText: 'e.g. nimal@gmail.com', validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email address' : null),
                  const SizedBox(height: 16),
                  _formField(isDark, 'Phone Number', Icons.phone_outlined, _phoneC, hintText: 'e.g. +94771234567', validator: (val) => val == null || !RegExp(r'^\+94\d{9}$').hasMatch(val) ? 'Format: +94 followed by 9 digits' : null),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Account'),
            isActive: _currentStep >= 1,
            content: Form(
              key: _step1Key,
              child: Column(
                children: [
                  _formField(isDark, 'Password', Icons.lock_outline, _passC, isPassword: true, hintText: 'Min 8 chars, 1 uppercase', validator: (val) {
                    if (val == null || val.length < 8) return 'Minimum 8 characters required';
                    if (!val.contains(RegExp(r'[A-Z]'))) return 'Must contain at least 1 uppercase letter';
                    return null;
                  }),
                  const SizedBox(height: 16),
                  const Text('Choose a strong password for your operator portal.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Credentials'),
            isActive: _currentStep >= 2,
            content: Form(
              key: _step2Key,
              child: Column(
                children: [
                  _formField(isDark, 'Operator ID', Icons.badge, _operatorIdC, hintText: 'e.g. RSOP26-001 or RSCOP26-001', validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Operator ID is required';
                    if (!val.startsWith('RSOP') && !val.startsWith('RSCOP')) return 'Must start with RSOP or RSCOP';
                    return null;
                  }),
                  const SizedBox(height: 16),
                  _formField(isDark, 'National Identity Card (NIC)', Icons.credit_card_outlined, _nicC, hintText: 'e.g. 199912345678 or 991234567V', validator: (val) {
                    if (val == null || (!RegExp(r'^\d{9}[vVxX]$').hasMatch(val) && !RegExp(r'^\d{12}$').hasMatch(val))) {
                      return 'Must be 9 digits+V/X or 12 digits';
                    }
                    return null;
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formField(bool isDark, String label, IconData icon, TextEditingController controller, {bool isPassword = false, TextInputType keyboardType = TextInputType.text, String? hintText, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: isPassword ? _obscurePass : false,
      keyboardType: keyboardType,
      style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700),
        hintText: hintText,
        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400, fontWeight: FontWeight.normal),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(icon, color: isDark ? Colors.white54 : Colors.grey.shade500),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility,
                    color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
                onPressed: () => setState(() => _obscurePass = !_obscurePass))
            : null,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}
