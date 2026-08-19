import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/features/auth/presentation/screens/otp_screen.dart';
import 'package:ridesync/core/widgets/custom_button.dart';

/// Passenger Signup Screen
/// - Name, Gmail only, Sri Lankan phone (+94), password
/// - Phone OTP verification after signup
class PassengerSignupScreen extends StatefulWidget {
  const PassengerSignupScreen({super.key});

  @override
  State<PassengerSignupScreen> createState() => _PassengerSignupScreenState();
}

class _PassengerSignupScreenState extends State<PassengerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmPassC = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _passC.dispose();
    _confirmPassC.dispose();
    super.dispose();
  }

  bool _isGmail(String email) => email.toLowerCase().endsWith('@gmail.com');

  bool _isValidSLPhone(String phone) => RegExp(r'^\+94\d{9}$').hasMatch(phone);

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    String phone = _phoneC.text.trim();
    if (phone.startsWith('0')) {
      phone = '+94${phone.substring(1)}';
    } else if (!phone.startsWith('+94')) {
      phone = '+94$phone';
    }

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.signupAsPassengerWithEmail(
        _nameC.text.trim(),
        _emailC.text.trim(),
        _passC.text.trim(),
        phone,
      );

      // After email signup, verify phone via OTP
      if (mounted) {
        _sendPhoneOtp(phone);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Signup failed';
      if (e.code == 'email-already-in-use') {
        msg = 'An account already exists with this email';
      } else if (e.code == 'weak-password') {
        msg = 'Password must be at least 6 characters';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email address';
      }
      _showError(msg);
    } catch (e) {
      _showError('Signup failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPhoneOtp(String normalizedPhone) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      verificationCompleted: (credential) async {
        // Auto-verified
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/main', (r) => false);
        }
      },
      verificationFailed: (e) {
        // Phone verification failed but account is created, proceed anyway
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/main', (r) => false);
        }
      },
      codeSent: (verificationId, _) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                verificationId: verificationId,
                phoneNumber: normalizedPhone,
                purpose: 'signup',
              ),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : AppColors.primaryNavy,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_add_rounded,
                          color: AppColors.primaryOrange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Passenger Account',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Join RideSync and travel smarter',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : AppColors.textLight,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Full Name
                _buildFormField(
                  isDark, 'Full Name', Icons.person_outline, _nameC,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length < 2) return 'Enter a valid name';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Gmail
                _buildFormField(
                  isDark, 'Gmail Address', Icons.email_outlined, _emailC,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!_isGmail(v.trim())) return 'Only Gmail addresses allowed';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Phone
                _buildFormField(
                  isDark, 'Phone (e.g. 771234567)', Icons.phone_outlined, _phoneC,
                  keyboardType: TextInputType.phone,
                  prefixText: '+94 ',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone is required';
                    
                    // We validate the full phone number assuming +94 is prepended
                    String phone = v.trim();
                    if (phone.startsWith('0')) {
                      phone = '+94${phone.substring(1)}';
                    } else if (!phone.startsWith('+94')) {
                      phone = '+94$phone';
                    }
                    
                    if (!_isValidSLPhone(phone)) {
                      return 'Enter a valid Sri Lankan number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Password
                _buildFormField(
                  isDark, 'Password', Icons.lock_outline, _passC,
                  isPassword: true,
                  obscure: _obscurePass,
                  onToggle: () => setState(() => _obscurePass = !_obscurePass),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Confirm Password
                _buildFormField(
                  isDark, 'Confirm Password', Icons.lock_outline, _confirmPassC,
                  isPassword: true,
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v != _passC.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18,
                          color: isDark ? Colors.white54 : Colors.blue.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'After signup, you\'ll receive an SMS code to verify your phone.',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark ? Colors.white54 : Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  CustomButton(
                      label: 'Create Account', onPressed: _handleSignup),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?',
                        style: TextStyle(
                            color:
                                isDark ? Colors.white60 : AppColors.textLight)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Sign In',
                          style: TextStyle(
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
    bool isDark,
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey),
        prefixText: prefixText,
        prefixStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
                onPressed: onToggle,
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
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
}
