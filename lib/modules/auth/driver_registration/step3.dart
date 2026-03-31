import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ridesync/modules/operator/providers/registration_provider.dart';
import 'package:ridesync/modules/auth/auth_provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/custom_button.dart';

/// Step 3: Review & Submit for Bus Operator Registration
class Step3 extends StatefulWidget {
  final VoidCallback onBack;

  const Step3({super.key, required this.onBack});

  @override
  State<Step3> createState() => _Step3State();
}

class _Step3State extends State<Step3> {
  bool _isSubmitting = false;
  bool _agreed = false;

  Future<void> _handleSubmit() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms')),
      );
      return;
    }

    final reg = Provider.of<RegistrationProvider>(context, listen: false);

    if (reg.email.isEmpty || reg.password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing credentials from Step 1.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Create User
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: reg.email, password: reg.password);
      String uid = cred.user!.uid;

      // 2. Save to Firestore users
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': 'operator',
        'status': 'pending_review',
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': reg.name,
        'email': reg.email,
        'phone': reg.phone,
      });

      // 3. Save to Firestore operators
      await FirebaseFirestore.instance.collection('operators').doc(uid).set({
        'name': reg.name,
        'email': reg.email,
        'phone': reg.phone,
        'heavyVehicleLicense': reg.heavyVehicleLicense,
        'yearOfIssuance': reg.yearOfIssuance,
        'status': 'pending_review',
      });

      // Update name in Firebase Auth metadata
      await cred.user!.updateDisplayName(reg.name);

      // Force refresh of auth state
      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();

      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      String msg = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        msg = 'An account already exists with this email';
      } else if (e.code == 'weak-password') {
        msg = 'Password is too weak';
      }
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reg = Provider.of<RegistrationProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          Row(
            children: [
              _stepDot(1, true),
              _stepLine(true),
              _stepDot(2, true),
              _stepLine(true),
              _stepDot(3, true),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Review & Submit',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Verify your details before submitting',
            style: TextStyle(
              color: isDark ? Colors.white54 : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 28),

          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                _infoRow(isDark, Icons.person_outline, 'Name', reg.name),
                _divider(isDark),
                _infoRow(isDark, Icons.email_outlined, 'Email', reg.email),
                _divider(isDark),
                _infoRow(isDark, Icons.phone_outlined, 'Phone', reg.phone),
                _divider(isDark),
                _infoRow(isDark, Icons.badge_outlined, 'License', reg.heavyVehicleLicense),
                _divider(isDark),
                _infoRow(isDark, Icons.calendar_today_outlined, 'Year', reg.yearOfIssuance),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Terms checkbox
          CheckboxListTile(
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primaryOrange,
            title: Text(
              'I confirm that all details are accurate and authorize RideSync to verify my credentials.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppColors.textLight,
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_isSubmitting)
            const Center(child: CircularProgressIndicator())
          else
            CustomButton(label: 'Submit Registration', onPressed: _handleSubmit),
          const SizedBox(height: 16),
          if (!_isSubmitting)
            Center(
              child: TextButton(
                onPressed: widget.onBack,
                child: Text(
                  '← Review Previous Steps',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(bool isDark, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryOrange),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.textLight,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      color: isDark ? Colors.white12 : Colors.grey.shade200,
      height: 1,
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
        child: active
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : Text(
                '$step',
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _stepLine(bool complete) {
    return Expanded(
      child: Container(
        height: 2,
        color: complete ? AppColors.primaryOrange : Colors.grey.shade300,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            const Text('Submitted!'),
          ],
        ),
        content: const Text(
          'Your registration is under review. Our team will verify your credentials and notify you soon.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/operator-main', (route) => false);
            },
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
