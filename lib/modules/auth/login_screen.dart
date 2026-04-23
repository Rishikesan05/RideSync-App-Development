import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:ridesync/modules/auth/auth_provider.dart';
import 'package:ridesync/modules/auth/user_model.dart';
import 'package:ridesync/modules/auth/otp_screen.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/custom_button.dart';

/// Redesigned Login Screen
/// - Email + password login (backup)
/// - Phone (+94) OTP login
/// - Forgot password link
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailC = TextEditingController();
  final TextEditingController _passwordC = TextEditingController();
  final TextEditingController _phoneC = TextEditingController(text: '+94');
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailC.dispose();
    _passwordC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  // ── Email/Password Login ──
  Future<void> _handleEmailLogin() async {
    final email = _emailC.text.trim();
    final password = _passwordC.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in both fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentRole == UserRole.operator) {
        await auth.loginAsOperator(email, password);
        if (mounted) Navigator.pushReplacementNamed(context, '/operator-main');
      } else {
        await auth.loginAsPassenger(email, password);
        if (mounted) Navigator.pushReplacementNamed(context, '/main');
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed';
      if (e.code == 'user-not-found') msg = 'No account found with this email';
      if (e.code == 'wrong-password') msg = 'Incorrect password';
      if (e.code == 'invalid-email') msg = 'Invalid email address';
      if (e.code == 'invalid-credential') msg = 'Invalid email or password';
      _showError(msg);
    } catch (e) {
      _showError('Login failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Phone OTP Login ──
  Future<void> _handlePhoneLogin() async {
    final phone = _phoneC.text.trim();
    if (!_isValidSriLankanNumber(phone)) {
      _showError('Enter a valid Sri Lankan number (+94XXXXXXXXX)');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolve on Android
          UserCredential userCred =
              await FirebaseAuth.instance.signInWithCredential(credential);
          if (userCred.user != null && mounted) {
            await Provider.of<AuthProvider>(context, listen: false)
                .syncPhonePassenger(userCred.user!);
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/main');
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showError(e.message ?? 'Verification failed');
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() => _isLoading = false);
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to send code: $e');
      }
    }
  }

  bool _isValidSriLankanNumber(String phone) {
    final regex = RegExp(r'^\+94\d{9}$');
    return regex.hasMatch(phone);
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final isOperator = auth.currentRole == UserRole.operator;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  height: 56,
                  width: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.directions_bus, size: 56),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isOperator
                    ? 'Sign in to manage your fleet'
                    : 'Sign in to continue your journey',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textLight,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 28),

              // Tab bar: Email | Phone
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      isDark ? Colors.white60 : AppColors.textLight,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Email Login'),
                    Tab(text: 'Phone Login'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Tab content
              SizedBox(
                height: 280,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEmailTab(isDark),
                    _buildPhoneTab(isDark),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppColors.textLight,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/role-selection'),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailTab(bool isDark) {
    return Column(
      children: [
        _buildField(isDark, 'Email', Icons.email_outlined, _emailC),
        const SizedBox(height: 16),
        _buildField(isDark, 'Password', Icons.lock_outline, _passwordC,
            isPassword: true),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
            child: const Text('Forgot Password?',
                style: TextStyle(color: AppColors.primaryOrange)),
          ),
        ),
        const SizedBox(height: 12),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomButton(label: 'Sign In', onPressed: _handleEmailLogin),
      ],
    );
  }

  Widget _buildPhoneTab(bool isDark) {
    return Column(
      children: [
        _buildField(
            isDark, 'Phone Number (+94XXXXXXXXX)', Icons.phone_outlined, _phoneC,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 8),
        Text(
          'We\'ll send a verification code via SMS',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white54 : AppColors.textLight,
          ),
        ),
        const SizedBox(height: 24),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomButton(label: 'Send OTP', onPressed: _handlePhoneLogin),
      ],
    );
  }

  Widget _buildField(
      bool isDark, String label, IconData icon, TextEditingController c,
      {bool isPassword = false,
      TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: c,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
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
      ),
    );
  }
}
