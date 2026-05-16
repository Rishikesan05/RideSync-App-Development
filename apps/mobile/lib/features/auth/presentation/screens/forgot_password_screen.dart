import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailC = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _handleReset() async {
    final email = _emailC.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String message = 'Something went wrong';
        if (e.code == 'user-not-found') {
          message = 'No account found with this email';
        } else if (e.code == 'invalid-email') {
          message = 'Please enter a valid email address';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : AppColors.primaryNavy,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Icon(
                _emailSent ? Icons.mark_email_read_rounded : Icons.lock_reset_rounded,
                size: 64,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(height: 24),
              Text(
                _emailSent ? 'Check Your Email' : 'Reset Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _emailSent
                    ? 'We\'ve sent a password reset link to ${_emailC.text.trim()}. Check your inbox and follow the link to reset your password.'
                    : 'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.white70 : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 40),
              if (!_emailSent) ...[
                TextFormField(
                  controller: _emailC,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                    prefixIcon: Icon(Icons.email_outlined, color: isDark ? Colors.white70 : Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryOrange),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  CustomButton(
                    label: 'Send Reset Link',
                    onPressed: _handleReset,
                  ),
              ] else ...[
                CustomButton(
                  label: 'Back to Login',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() => _emailSent = false);
                    },
                    child: Text(
                      'Didn\'t receive the email? Try again',
                      style: TextStyle(color: isDark ? AppColors.primaryOrange : AppColors.primaryNavy),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
