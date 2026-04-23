import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/modules/auth/providers/auth_provider.dart';
import 'package:ridesync/modules/auth/data/user_model.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/custom_button.dart';

// Login screen with Role-based routing
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (auth.currentRole == UserRole.operator) {
        await auth.loginAsOperator(email, password);
        // AuthWrapper handles routing based on auth state
        if (mounted) Navigator.pushReplacementNamed(context, '/operator-main');
      } else {
        await auth.loginAsPassenger(email, password);
        if (mounted) Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final isPassenger = auth.currentRole == UserRole.passenger;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  height: 64,
                  width: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.directions_bus, size: 64),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPassenger
                    ? 'Sign in to continue your journey'
                    : 'Sign in to manage your bus fleet',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 48),
              _buildTextField(context, 'Email', Icons.email_outlined, _emailController),
              const SizedBox(height: 20),
              _buildTextField(
                context,
                'Password',
                Icons.lock_outline,
                _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: isDark ? AppColors.primaryOrange : null),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                CustomButton(
                  label: isPassenger ? 'Sign In' : 'Operator Sign In',
                  onPressed: _handleLogin,
                ),
              if (isPassenger) ...[
                const SizedBox(height: 16),
                CustomButton(
                  label: 'Login with Phone Number',
                  color: AppColors.primaryNavy,
                  onPressed: () {
                    Navigator.pushNamed(context, '/phone-auth');
                  },
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/role-selection'),
                    child: Text(
                      'Change role',
                      style: TextStyle(
                        color: isDark ? AppColors.primaryOrange : null,
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

  Widget _buildTextField(
    BuildContext context,
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryOrange),
        ),
      ),
    );
  }
}





