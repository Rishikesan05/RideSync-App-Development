import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/modules/auth/auth_provider.dart';
import 'package:ridesync/modules/auth/otp_screen.dart';

/// Combined Passenger Auth Screen
/// CORRECT FLOW:
///   Sign Up → collect details → send OTP → verify OTP → THEN create account
///   Sign In → email+password  OR  phone OTP → navigate to main
class PassengerAuthChoiceScreen extends StatefulWidget {
  const PassengerAuthChoiceScreen({super.key});

  @override
  State<PassengerAuthChoiceScreen> createState() => _PassengerAuthChoiceScreenState();
}

class _PassengerAuthChoiceScreenState extends State<PassengerAuthChoiceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // Login controllers
  final _loginEmailC = TextEditingController();
  final _loginPassC  = TextEditingController();
  final _loginPhoneC = TextEditingController(text: '+94');

  // Signup controllers
  final _signupNameC    = TextEditingController();
  final _signupEmailC   = TextEditingController();
  final _signupPhoneC   = TextEditingController(text: '+94');
  final _signupPassC    = TextEditingController();
  final _signupConfirmC = TextEditingController();

  bool _loginLoading        = false;
  bool _signupLoading       = false;
  bool _loginObscure        = true;
  bool _signupObscure       = true;
  bool _signupConfirmObscure = true;
  bool _loginByPhone        = false;

  final _loginFormKey  = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  static const _orange = AppColors.primaryOrange;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmailC.dispose();
    _loginPassC.dispose();
    _loginPhoneC.dispose();
    _signupNameC.dispose();
    _signupEmailC.dispose();
    _signupPhoneC.dispose();
    _signupPassC.dispose();
    _signupConfirmC.dispose();
    super.dispose();
  }

  bool _isGmail(String e) => e.toLowerCase().endsWith('@gmail.com');
  bool _isValidSLPhone(String p) => RegExp(r'^\+94\d{9}$').hasMatch(p);

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
    ));
  }

  // ─── EMAIL LOGIN ───────────────────────────────────────────────────────────
  Future<void> _handleEmailLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loginLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.loginAsPassenger(
          _loginEmailC.text.trim(), _loginPassC.text.trim());
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/main', (r) => false);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed';
      if (e.code == 'user-not-found')  msg = 'No account found with this email';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = 'Incorrect email or password';
      }
      if (e.code == 'invalid-email') msg = 'Invalid email address';
      _showSnack(msg);
    } catch (e) {
      _showSnack('Login failed: $e');
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  // ─── PHONE OTP LOGIN ───────────────────────────────────────────────────────
  Future<void> _handlePhoneLogin() async {
    final phone = _loginPhoneC.text.trim();
    if (!_isValidSLPhone(phone)) {
      _showSnack('Enter a valid Sri Lankan number (+94XXXXXXXXX)');
      return;
    }
    setState(() => _loginLoading = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        final c = await FirebaseAuth.instance.signInWithCredential(credential);
        if (c.user != null && mounted) {
          await Provider.of<AuthProvider>(context, listen: false)
              .syncPhonePassenger(c.user!);
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/main', (r) => false);
          }
        }
      },
      verificationFailed: (e) {
        if (mounted) {
          setState(() => _loginLoading = false);
          _showSnack(e.message ?? 'Verification failed');
        }
      },
      codeSent: (verificationId, _) {
        if (mounted) {
          setState(() => _loginLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                verificationId: verificationId,
                phoneNumber: phone,
                purpose: 'login',
              ),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // ─── SIGNUP — OTP FIRST, ACCOUNT CREATION AFTER ───────────────────────────
  Future<void> _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;

    // Capture all values before async gap
    final name    = _signupNameC.text.trim();
    final email   = _signupEmailC.text.trim();
    final phone   = _signupPhoneC.text.trim();
    final pass    = _signupPassC.text.trim();

    setState(() => _signupLoading = true);

    // STEP 1 — Send OTP to phone. Account is NOT created yet.
    // The OtpScreen will call back to create the account only after OTP success.
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        // Auto-verified (rare) — create account immediately
        setState(() => _signupLoading = false);
        await _createAccountAfterOtp(name, email, phone, pass, credential);
      },
      verificationFailed: (e) {
        if (mounted) {
          setState(() => _signupLoading = false);
          String msg = e.message ?? 'Phone verification failed';
          if (msg.contains('blocked')) {
            msg = 'Too many attempts. Use the test number +94771234567 or try later.';
          }
          if (msg.contains('region')) {
            msg = 'SMS not enabled for Sri Lanka yet. Please use test number.';
          }
          _showSnack(msg);
        }
      },
      codeSent: (verificationId, resendToken) {
        if (mounted) {
          setState(() => _signupLoading = false);
          // Navigate to OTP screen — pass signup data so account is created AFTER OTP
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                verificationId: verificationId,
                phoneNumber: phone,
                purpose: 'signup',
                // Extra data for post-OTP account creation
                signupName:  name,
                signupEmail: email,
                signupPass:  pass,
              ),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (_) {
        if (mounted) setState(() => _signupLoading = false);
      },
    );
  }

  // Called after OTP is confirmed (auto-verification path)
  Future<void> _createAccountAfterOtp(
    String name, String email, String phone, String pass,
    PhoneAuthCredential credential,
  ) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // Sign in with phone credential first to verify
      final phoneUser = await FirebaseAuth.instance.signInWithCredential(credential);
      if (phoneUser.user == null) return;

      // Now create the email+password account (links phone number)
      await auth.signupAsPassengerWithEmail(name, email, pass, phone);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/main', (r) => false);
      }
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Account creation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: isDark ? Colors.white : AppColors.textDark),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_pin_circle_rounded,
                            color: _orange, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Passenger',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textDark,
                              )),
                          Text('Sign in or create your account',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.textLight)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tab bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                    child: TabBar(
                      controller: _tab,
                      indicator: BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor:
                          isDark ? Colors.white54 : AppColors.textLight,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab content ──
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildLoginTab(isDark),
                  _buildSignupTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Login Tab ──────────────────────────────────────────────────────────────
  Widget _buildLoginTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle
            Row(
              children: [
                _toggleChip('Email', !_loginByPhone, isDark,
                    () => setState(() => _loginByPhone = false)),
                const SizedBox(width: 8),
                _toggleChip('Phone OTP', _loginByPhone, isDark,
                    () => setState(() => _loginByPhone = true)),
              ],
            ),
            const SizedBox(height: 20),

            if (!_loginByPhone) ...[
              _formField(isDark, 'Gmail Address', Icons.email_outlined,
                  _loginEmailC,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    return null;
                  }),
              const SizedBox(height: 14),
              _formField(isDark, 'Password', Icons.lock_outline, _loginPassC,
                  isPassword: true,
                  obscure: _loginObscure,
                  onToggle: () => setState(() => _loginObscure = !_loginObscure),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  }),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgot-password'),
                  child: const Text('Forgot Password?',
                      style: TextStyle(color: _orange, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),
              _loginLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _orange))
                  : _bigButton('Sign In', _orange, _handleEmailLogin),
            ] else ...[
              _formField(
                  isDark, 'Phone Number (+94XXXXXXXXX)',
                  Icons.phone_outlined, _loginPhoneC,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (!_isValidSLPhone(v ?? '')) {
                      return 'Enter a valid Sri Lankan number';
                    }
                    return null;
                  }),
              const SizedBox(height: 10),
              Text('An OTP will be sent to your phone',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : AppColors.textLight)),
              const SizedBox(height: 24),
              _loginLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _orange))
                  : _bigButton('Send OTP', _orange, _handlePhoneLogin),
            ],
          ],
        ),
      ),
    );
  }

  // ── Signup Tab ─────────────────────────────────────────────────────────────
  Widget _buildSignupTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _signupFormKey,
        child: Column(
          children: [
            // Flow indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined,
                      color: _orange, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Fill details → OTP sent to your phone → verify → account created',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : AppColors.textLight,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            _formField(isDark, 'Full Name', Icons.person_outline, _signupNameC,
                validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name is required';
              return null;
            }),
            const SizedBox(height: 14),
            _formField(isDark, 'Gmail Address', Icons.email_outlined,
                _signupEmailC,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!_isGmail(v.trim())) return 'Only Gmail addresses are accepted';
              return null;
            }),
            const SizedBox(height: 14),
            _formField(
                isDark, 'Phone (+94XXXXXXXXX)', Icons.phone_outlined,
                _signupPhoneC,
                keyboardType: TextInputType.phone,
                validator: (v) {
              if (v == null || !_isValidSLPhone(v.trim())) {
                return 'Enter a valid Sri Lankan number (+94XXXXXXXXX)';
              }
              return null;
            }),
            const SizedBox(height: 14),
            _formField(isDark, 'Password', Icons.lock_outline, _signupPassC,
                isPassword: true,
                obscure: _signupObscure,
                onToggle: () =>
                    setState(() => _signupObscure = !_signupObscure),
                validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            }),
            const SizedBox(height: 14),
            _formField(isDark, 'Confirm Password', Icons.lock_outline,
                _signupConfirmC,
                isPassword: true,
                obscure: _signupConfirmObscure,
                onToggle: () => setState(
                    () => _signupConfirmObscure = !_signupConfirmObscure),
                validator: (v) {
              if (v != _signupPassC.text) return 'Passwords do not match';
              return null;
            }),
            const SizedBox(height: 20),
            _signupLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _orange))
                : _bigButton(
                    'Send OTP & Continue', _orange, _handleSignup),
          ],
        ),
      ),
    );
  }

  Widget _toggleChip(
      String label, bool active, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? _orange
              : (isDark ? Colors.white12 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: active
                  ? Colors.white
                  : (isDark ? Colors.white54 : AppColors.textLight),
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            )),
      ),
    );
  }

  Widget _bigButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _formField(
    bool isDark,
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
          color: isDark ? Colors.white : Colors.black, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey.shade500,
            fontSize: 14),
        prefixIcon: Icon(icon,
            color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                    size: 20),
                onPressed: onToggle)
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
