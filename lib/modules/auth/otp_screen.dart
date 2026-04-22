import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:ridesync/modules/auth/auth_provider.dart';
import 'package:ridesync/core/constants.dart';

/// Reusable OTP verification screen.
///
/// For LOGIN  : verifies OTP → navigates to /main
/// For SIGNUP : verifies OTP → THEN creates account → navigates to /main
///              Account data passed via [signupName], [signupEmail], [signupPass]
class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String purpose; // 'login' | 'signup'

  // Only for signup — passed from PassengerAuthChoiceScreen
  final String? signupName;
  final String? signupEmail;
  final String? signupPass;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.purpose = 'login',
    this.signupName,
    this.signupEmail,
    this.signupPass,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String _statusMsg = '';

  String get _otp => _controllers.map((c) => c.text).join();

  static const _orange = AppColors.primaryOrange;

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
    ));
  }

  Future<void> _verifyOtp() async {
    final otp = _otp;
    if (otp.length < 6) {
      _showSnack('Please enter all 6 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMsg = 'Verifying code...';
    });

    try {
      // Step 1 — verify phone OTP
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );
      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCred.user == null || !mounted) return;

      if (widget.purpose == 'signup') {
        // Step 2 (signup only) — OTP verified ✅, NOW create the account
        setState(() => _statusMsg = 'OTP verified! Creating your account...');

        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.signupAsPassengerWithEmail(
          widget.signupName ?? '',
          widget.signupEmail ?? '',
          widget.signupPass ?? '',
          widget.phoneNumber,
        );

        if (mounted) {
          _showSnack('Account created successfully!', isError: false);
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/main', (r) => false);
          }
        }
      } else {
        // Login — sync profile and proceed
        await Provider.of<AuthProvider>(context, listen: false)
            .syncPhonePassenger(userCred.user!);
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/main', (r) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'Verification failed';
      if (e.code == 'invalid-verification-code') {
        msg = 'Wrong OTP code. Please check and try again.';
      } else if (e.code == 'session-expired') {
        msg = 'Code expired. Go back and request a new one.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'An account with this email already exists. Please sign in.';
      }
      _showSnack(msg);
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSignup = widget.purpose == 'signup';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : AppColors.textDark,
        title: Text(
          isSignup ? 'Verify & Create Account' : 'Phone Verification',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.sms_outlined, size: 40, color: _orange),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                isSignup ? 'One Last Step!' : 'Enter Verification Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                isSignup
                    ? 'We sent a 6-digit code to\n${widget.phoneNumber}\n\nEnter it to verify your number and create your account.'
                    : 'We sent a 6-digit code to\n${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark ? Colors.white60 : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 32),

              // Signup step indicator
              if (isSignup) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stepDot(1, true, 'Details', isDark),
                    _stepLine(),
                    _stepDot(2, true, 'OTP', isDark),
                    _stepLine(),
                    _stepDot(3, false, 'Account', isDark),
                  ],
                ),
                const SizedBox(height: 28),
              ],

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 46, height: 56,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _orange, width: 2),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.grey.shade50,
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && i < 5) {
                          _focusNodes[i + 1].requestFocus();
                        } else if (val.isEmpty && i > 0) {
                          _focusNodes[i - 1].requestFocus();
                        }
                        // Auto-submit when all 6 entered
                        if (_otp.length == 6) _verifyOtp();
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Status message while loading
              if (_isLoading && _statusMsg.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_statusMsg,
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : AppColors.textLight)),
                ),

              const Spacer(),

              // Verify button
              _isLoading
                  ? const CircularProgressIndicator(color: _orange)
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          isSignup ? 'Verify & Create Account' : 'Verify Code',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
              const SizedBox(height: 14),

              // Resend
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('← Go back to resend code',
                    style: TextStyle(color: _orange, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepDot(int num, bool done, String label, bool isDark) {
    return Column(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: done ? _orange : (isDark ? Colors.white12 : Colors.grey.shade200),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text('$num',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: done ? _orange : (isDark ? Colors.white38 : Colors.grey))),
      ],
    );
  }

  Widget _stepLine() {
    return Container(
        width: 40, height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: _orange.withValues(alpha: 0.3));
  }
}
