import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_button.dart';

// Account tab handling Guest vs. Authenticated states
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final bool isLoggedIn = authProvider.isAuthenticated;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context, authProvider, isDark),
              if (isLoggedIn) _buildStatsRow(authProvider, isDark),
              _buildMenuSection(
                context,
                isLoggedIn,
                authProvider,
                settingsProvider,
                isDark,
              ),
              if (isLoggedIn) _buildLogoutButton(context, authProvider),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.padding),
      child: Column(
        children: [
          const SizedBox(height: 20),
          if (auth.isAuthenticated)
            _buildProfileHeader(auth, isDark)
          else
            _buildGuestHeader(context, auth, isDark),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider auth, bool isDark) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryOrange, width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: isDark
                    ? Colors.grey[800]
                    : const Color(0xFFE2E8F0),
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: isDark ? Colors.white : AppColors.primaryNavy,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryOrange,
                child: const Icon(Icons.edit, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          auth.user?.name ?? 'User Name',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        Text(
          'Member Since ${auth.user?.joinYear ?? 2024}',
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestHeader(
    BuildContext context,
    AuthProvider auth,
    bool isDark,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: isDark
              ? Colors.white10
              : AppColors.primaryNavy.withValues(alpha: 0.1),
          child: Icon(
            Icons.person_outline,
            size: 60,
            color: isDark ? Colors.white : AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 24),
        CustomButton(
          label: 'Login / Sign Up',
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
        ),
      ],
    );
  }

  Widget _buildStatsRow(AuthProvider auth, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(
            'Total Rides',
            '${auth.user?.totalRides ?? 0}',
            isDark,
          ),
          _buildStatCard(
            'Rating',
            '${auth.user?.rating ?? 5.0}',
            isDark,
            icon: Icons.star,
          ),
          _buildStatCard(
            'Loyalty Points',
            '${auth.user?.loyaltyPoints ?? 0}',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    bool isDark, {
    IconData? icon,
  }) {
    return Expanded(
      child: Card(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
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
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    bool isLoggedIn,
    AuthProvider auth,
    SettingsProvider settings,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppStyles.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoggedIn) ...[
            Text(
              'PREFERENCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              Icons.person_outline,
              'Personal Information',
              isDark,
            ),
            _buildMenuItem(context, Icons.history, 'Ride History', isDark),
            _buildMenuItem(
              context,
              Icons.card_giftcard,
              'Loyalty Rewards',
              isDark,
            ),
            _buildMenuItem(context, Icons.security, 'Security', isDark),
            const SizedBox(height: 24),
          ],
          Text(
            'GENERAL SETTINGS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            Icons.notifications_none,
            'Notifications',
            isDark,
            trailing: Switch(
              value: settings.isNotificationsEnabled,
              onChanged: (value) => settings.toggleNotifications(value),
              activeThumbColor: Colors.green,
            ),
          ),
          _buildMenuItem(
            context,
            Icons.language,
            'Language',
            isDark,
            subTitle: settings.selectedLanguage,
            onTap: () => _showLanguageDialog(context, settings),
          ),
          _buildMenuItem(
            context,
            Icons.dark_mode_outlined,
            'Appearance',
            isDark,
            subTitle: _getThemeName(settings.themeMode),
            onTap: () => _showAppearanceDialog(context, settings),
          ),
          const SizedBox(height: 24),
          Text(
            'SUPPORT & INFO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(context, Icons.help_outline, 'Help Center', isDark),
          _buildMenuItem(context, Icons.info_outline, 'About RideSync', isDark),
          _buildMenuItem(
            context,
            Icons.privacy_tip_outlined,
            'Privacy Policy',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    bool isDark, {
    Widget? trailing,
    String? subTitle,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        leading: Icon(
          icon,
          color: isDark ? Colors.white : AppColors.primaryNavy,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: subTitle != null
            ? Text(
                subTitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey,
                ),
              )
            : null,
        trailing:
            trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isDark ? Colors.white70 : AppColors.textLight,
            ),
        onTap:
            onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title details coming soon!')),
              );
            },
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
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

  Widget _themeOption(
    BuildContext context,
    String title,
    ThemeMode mode,
    SettingsProvider settings,
  ) {
    return ListTile(
      title: Text(title),
      trailing: settings.themeMode == mode
          ? const Icon(Icons.check, color: AppColors.primaryOrange)
          : null,
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$title details coming soon!')));
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

  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.padding),
      child: CustomButton(
        label: 'Log Out',
        color: AppColors.primaryOrange,
        icon: Icons.logout,
        onPressed: () {
          auth.logout();
          Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
        },
      ),
    );
  }
}
