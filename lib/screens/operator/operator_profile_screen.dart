import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_button.dart';

class OperatorProfileScreen extends StatelessWidget {
  const OperatorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(context, auth, isDark),
              _buildQuickStats(auth, isDark),
              _buildProfessionalInfo(context, isDark),
              _buildSettingsSection(context, settings, auth, isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AuthProvider auth, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryOrange, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 70,
                    color: isDark ? Colors.white : AppColors.primaryNavy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            auth.user?.name ?? 'Marcus Thompson',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Senior Bus Operator',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(AuthProvider auth, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statItem('Rating', auth.user?.rating.toString() ?? '4.8', Icons.star, Colors.amber, isDark),
          const SizedBox(width: 12),
          _statItem('Trips', auth.user?.totalRides.toString() ?? '450', Icons.route, AppColors.primaryOrange, isDark),
          const SizedBox(width: 12),
          _statItem('Exp.', '3 Yrs', Icons.timer, Colors.blue, isDark),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isDark) BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white70 : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfo(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('OPERATOR DETAILS', isDark),
          const SizedBox(height: 12),
          _buildInfoTile(Icons.badge_outlined, 'License Number', 'WP-LP-45920', isDark),
          _buildInfoTile(Icons.directions_bus_outlined, 'Assigned Vehicle', 'NA-4052 (Volvo B11R)', isDark),
          _buildInfoTile(Icons.work_outline, 'Company', 'Intercity Express Ltd.', isDark),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, SettingsProvider settings, AuthProvider auth, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('PREFERENCES', isDark),
          const SizedBox(height: 12),
          _buildMenuTile(context, Icons.notifications_none, 'Notifications', isDark, 
            trailing: Switch(
              value: settings.isNotificationsEnabled, 
              onChanged: (v) => settings.toggleNotifications(v),
              activeTrackColor: Colors.green.withValues(alpha: 0.5),
              activeThumbColor: Colors.green,
            )
          ),
          _buildMenuTile(context, Icons.dark_mode_outlined, 'Appearance', isDark, 
            subTitle: _getThemeName(settings.themeMode),
            onTap: () => _showAppearanceDialog(context, settings),
          ),
          _buildMenuTile(
            context, 
            Icons.language, 
            'Language', 
            isDark, 
            subTitle: settings.selectedLanguage,
            onTap: () => _showLanguageDialog(context, settings),
          ),
          const SizedBox(height: 32),
          CustomButton(
            label: 'Log Out',
            onPressed: () {
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
            },
            color: AppColors.primaryOrange,
            icon: Icons.logout,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: isDark ? Colors.white38 : AppColors.textLight.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryOrange),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : AppColors.textLight),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, IconData icon, String title, bool isDark, {Widget? trailing, String? subTitle, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        leading: Icon(icon, color: isDark ? Colors.white : AppColors.primaryNavy),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textDark)),
        subtitle: subTitle != null ? Text(subTitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
        trailing: trailing ?? Icon(Icons.chevron_right, color: isDark ? Colors.white30 : Colors.grey),
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'System Default';
      case ThemeMode.light: return 'Light Mode';
      case ThemeMode.dark: return 'Dark Mode';
    }
  }

  void _showAppearanceDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Appearance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _themeOption(context, 'System Default', ThemeMode.system, settings),
            _themeOption(context, 'Light Mode', ThemeMode.light, settings),
            _themeOption(context, 'Dark Mode', ThemeMode.dark, settings),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(BuildContext context, String title, ThemeMode mode, SettingsProvider settings) {
    return ListTile(
      title: Text(title),
      trailing: settings.themeMode == mode ? const Icon(Icons.check, color: AppColors.primaryOrange) : null,
      onTap: () {
        settings.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Sinhala', 'Tamil'].map((lang) {
            return ListTile(
              title: Text(lang),
              trailing: settings.selectedLanguage == lang
                  ? const Icon(Icons.check, color: AppColors.primaryOrange)
                  : null,
              onTap: () {
                // Mock selection logic
                // settings.setSelectedLanguage(lang); // if provider supports it
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$lang selection coming soon!')),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
