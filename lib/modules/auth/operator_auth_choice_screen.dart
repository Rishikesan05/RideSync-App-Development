import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/modules/auth/auth_provider.dart';

/// Combined Operator Auth Screen
/// Login (email+password) and Register (3-step) in one screen
/// Visually distinct from passenger screen — uses blue accent
class OperatorAuthChoiceScreen extends StatefulWidget {
  const OperatorAuthChoiceScreen({super.key});

  @override
  State<OperatorAuthChoiceScreen> createState() => _OperatorAuthChoiceScreenState();
}

class _OperatorAuthChoiceScreenState extends State<OperatorAuthChoiceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  final _formKey = GlobalKey<FormState>();

  static const _blue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.loginAsOperator(_emailC.text.trim(), _passC.text.trim());
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/operator-main', (r) => false);
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed';
      if (e.code == 'user-not-found') msg = 'No operator account found with this email';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') msg = 'Incorrect email or password';
      _showSnack(msg);
    } catch (e) {
      _showSnack('Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: isDark ? Colors.white : AppColors.textDark),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_bus_filled_rounded,
                            color: _blue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bus Operator',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textDark,
                              )),
                          Text('Sign in or register your fleet',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white54 : AppColors.textLight)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tab bar — blue accent (operator colour)
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                    child: TabBar(
                      controller: _tab,
                      indicator: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark ? Colors.white54 : AppColors.textLight,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: const [Tab(text: 'Sign In'), Tab(text: 'Register Fleet')],
                    ),
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildLoginTab(isDark),
                  _buildRegisterTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Operator login info box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings_outlined, color: _blue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Operator accounts are verified by RideSync. Login with your approved credentials.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : AppColors.textLight,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            _formField(isDark, 'Gmail Address', Icons.email_outlined, _emailC,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  return null;
                }),
            const SizedBox(height: 14),
            _formField(isDark, 'Password', Icons.lock_outline, _passC,
                isPassword: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  return null;
                }),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                child: const Text('Forgot Password?',
                    style: TextStyle(color: _blue, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 8),
            _loading
                ? const Center(child: CircularProgressIndicator(color: _blue))
                : _bigButton('Sign In', _blue, _handleLogin),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Registration steps info
          _stepInfo(isDark, 1, 'Personal Details', 'Name, Gmail & Sri Lankan phone'),
          const SizedBox(height: 12),
          _stepInfo(isDark, 2, 'Professional Credentials', 'Heavy vehicle license details'),
          const SizedBox(height: 12),
          _stepInfo(isDark, 3, 'Review & Submit', 'Confirm and submit for approval'),
          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.amber.withValues(alpha: 0.1) : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'After registration, your account will be reviewed within 24–48 hours before approval.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.amber.shade200 : Colors.amber.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _bigButton('Start Registration (3 Steps)', _blue,
              () => Navigator.pushNamed(context, '/driver-registration')),
        ],
      ),
    );
  }

  Widget _stepInfo(bool isDark, int step, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$step',
                  style: const TextStyle(
                      color: _blue, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textDark,
                      fontSize: 14,
                    )),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : AppColors.textLight,
                    )),
              ],
            ),
          ),
        ],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _formField(
    bool isDark,
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscure : false,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(icon, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                    color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure))
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
