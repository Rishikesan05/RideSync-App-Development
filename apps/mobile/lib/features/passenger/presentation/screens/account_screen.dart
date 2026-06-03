import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/core/providers/settings_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/home_provider.dart';
import 'package:ridesync/core/widgets/custom_button.dart';
import 'package:ridesync/features/passenger/presentation/screens/my_bookings_screen.dart';
import 'package:ridesync/core/localization/translations.dart';
import 'dart:ui';

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // The orange header section that scrolls
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: _buildHeader(context, authProvider, isDark),
            ),
            const SizedBox(height: 16),
            if (isLoggedIn) _buildStatsRow(authProvider, isDark),
            const SizedBox(height: 16),
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
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.padding),
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
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: isDark
                    ? Colors.grey[800]
                    : Colors.white,
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: isDark ? Colors.white : AppColors.primaryOrange,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.edit, size: 18, color: AppColors.primaryOrange),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          auth.user?.name ?? 'User Name',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          'Member Since ${auth.user?.joinYear ?? 2024}',
          style: const TextStyle(
            color: Colors.white70,
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
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: const Icon(
            Icons.person_outline,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text('Login / Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildStatsRow(AuthProvider auth, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.padding),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background colorful glowing blob to make the glassmorphism pop
          Container(
            width: 250,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryOrange.withValues(alpha: 0.5), Colors.blueAccent.withValues(alpha: 0.5)],
              ),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(color: AppColors.primaryOrange.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 10)
              ]
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                'Total Rides',
                '${auth.user?.totalRides ?? 0}',
                isDark,
                icon: Icons.directions_car,
                iconColor: Colors.blueAccent,
              ),
              _buildStatCard(
                'Rating',
                '${auth.user?.rating ?? 5.0}',
                isDark,
                icon: Icons.star,
                iconColor: Colors.amber,
              ),
              _buildStatCard(
                'Loyalty',
                '${auth.user?.loyaltyPoints ?? 0}',
                isDark,
                icon: Icons.stars,
                iconColor: AppColors.primaryOrange,
              ),
            ],
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
    Color iconColor = Colors.amber,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: iconColor),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white70 : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
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
              subTitle: 'Name, email, and phone validation',
            ),
            _buildMenuItem(
              context,
              Icons.star_border,
              'Favourite Routes',
              isDark,
              subTitle: 'Manage frequent destinations',
              onTap: () => _showFavouriteRoutesDialog(context, isDark),
            ),
            _buildMenuItem(
              context, 
              Icons.history, 
              'Ride History', 
              isDark,
              subTitle: 'View bookings and ride transactions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
              ),
            ),
            _buildMenuItem(
              context,
              Icons.card_giftcard,
              'Loyalty Rewards',
              isDark,
              subTitle: 'Check points and premium tier benefits',
            ),
            _buildMenuItem(
              context,
              Icons.security,
              'Security',
              isDark,
              subTitle: 'Password and biometrics configurations',
            ),
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
          const SizedBox(height: 16),
          _buildProminentSettingCard(
            context,
            Icons.notifications_active,
            'Notifications',
            'Toggle push alerts',
            isDark,
            trailing: Switch(
              value: settings.isNotificationsEnabled,
              onChanged: (value) => settings.toggleNotifications(value),
              activeThumbColor: AppColors.primaryOrange,
            ),
            color: Colors.blueAccent,
          ),
          _buildProminentSettingCard(
            context,
            Icons.language,
            Translations.translate(context, 'language'),
            'Current: ${settings.selectedLanguage}',
            isDark,
            onTap: () => _showLanguageDialog(context, settings),
            color: Colors.teal,
          ),
          _buildProminentSettingCard(
            context,
            Icons.dark_mode,
            Translations.translate(context, 'appearance'),
            'Current: ${_getThemeName(settings.themeMode)}',
            isDark,
            onTap: () => _showAppearanceDialog(context, settings),
            color: Colors.deepPurpleAccent,
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
          _buildMenuItem(
            context,
            Icons.help_outline,
            'Help Center',
            isDark,
            subTitle: 'Get support and view FAQs',
          ),
          _buildMenuItem(
            context,
            Icons.info_outline,
            'About RideSync',
            isDark,
            subTitle: 'App version info and guidelines',
          ),
          _buildMenuItem(
            context,
            Icons.privacy_tip_outlined,
            'Privacy Policy',
            isDark,
            subTitle: 'Read terms of service & data policies',
          ),
        ],
      ),
    );
  }

  Widget _buildProminentSettingCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool isDark, {
    Widget? trailing,
    VoidCallback? onTap,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: isDark ? Colors.white70 : AppColors.textLight,
                  size: 14,
                ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF1F5F9)], // Very soft light slate gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.primaryNavy.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? Colors.white : AppColors.primaryNavy,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: subTitle != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    subTitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                )
              : null,
          trailing: trailing ??
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: isDark ? Colors.white70 : AppColors.textLight,
              ),
          onTap: onTap ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title details coming soon!')),
                );
              },
        ),
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
        settings.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.translate(context, 'select_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Sinhala', 'Tamil'].map((lang) {
            return ListTile(
              title: Text(lang),
              trailing: settings.selectedLanguage == lang
                  ? const Icon(Icons.check, color: AppColors.primaryOrange)
                  : null,
              onTap: () {
                settings.setLanguage(lang);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(Translations.translate(context, 'language_changed'))),
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
        label: Translations.translate(context, 'logout'),
        color: AppColors.primaryOrange,
        icon: Icons.logout,
        onPressed: () {
          auth.logout();
          Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
        },
      ),
    );
  }  void _showFavouriteRoutesDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => _FavouriteRoutesDialog(isDark: isDark),
    );
  }
}

class _FavouriteRoutesDialog extends StatefulWidget {
  final bool isDark;
  const _FavouriteRoutesDialog({required this.isDark});

  @override
  State<_FavouriteRoutesDialog> createState() => _FavouriteRoutesDialogState();
}

class _FavouriteRoutesDialogState extends State<_FavouriteRoutesDialog> {
  bool _isAdding = false;
  String? _editingId;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _originCtrl = TextEditingController();
  final TextEditingController _destCtrl = TextEditingController();

  void _resetForm() {
    setState(() {
      _isAdding = false;
      _editingId = null;
    });
    _titleCtrl.clear();
    _originCtrl.clear();
    _destCtrl.clear();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _originCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();

    return AlertDialog(
      backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
      title: Text(_editingId != null ? 'Edit Route' : 'Favourite Routes'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isAdding
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Nickname (e.g. Gym)'),
                  ),
                  TextField(
                    controller: _originCtrl,
                    decoration: const InputDecoration(labelText: 'Origin (e.g. Nugegoda)'),
                  ),
                  TextField(
                    controller: _destCtrl,
                    decoration: const InputDecoration(labelText: 'Destination (e.g. Fort)'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _resetForm,
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_titleCtrl.text.isNotEmpty && _originCtrl.text.isNotEmpty && _destCtrl.text.isNotEmpty) {
                            if (_editingId != null) {
                              homeProvider.editFavouriteRoute(_editingId!, _titleCtrl.text, _originCtrl.text, _destCtrl.text);
                            } else {
                              homeProvider.addFavouriteRoute(_titleCtrl.text, _originCtrl.text, _destCtrl.text);
                            }
                            _resetForm();
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: homeProvider.favouriteRoutes.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No favourite routes yet', style: TextStyle(color: AppColors.textLight)),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: homeProvider.favouriteRoutes.length,
                            itemBuilder: (context, index) {
                              final route = homeProvider.favouriteRoutes[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(route['title'] ?? ''),
                                subtitle: Text('${route['origin']} -> ${route['destination']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 16),
                                      onPressed: () {
                                        setState(() {
                                          _isAdding = true;
                                          _editingId = route['id'];
                                          _titleCtrl.text = route['title'] ?? '';
                                          _originCtrl.text = route['origin'] ?? '';
                                          _destCtrl.text = route['destination'] ?? '';
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                      onPressed: () {
                                        homeProvider.deleteFavouriteRoute(route['id']!);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {
                      _isAdding = true;
                      _editingId = null;
                    }),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Custom Route'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
                  ),
                ],
              ),
      ),
    );
  }
}
