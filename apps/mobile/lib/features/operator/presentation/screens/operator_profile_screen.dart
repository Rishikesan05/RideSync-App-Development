import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/core/providers/settings_provider.dart';
import 'package:ridesync/core/widgets/custom_button.dart';
import 'package:ridesync/core/localization/translations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OperatorProfileScreen extends StatefulWidget {
  const OperatorProfileScreen({super.key});

  @override
  State<OperatorProfileScreen> createState() => _OperatorProfileScreenState();
}

class _OperatorProfileScreenState extends State<OperatorProfileScreen> {
  Map<String, dynamic>? _operatorProfile;
  int _completedTripsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.user?.id;
    if (uid == null) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('operators').doc(uid).get();
      final profileData = doc.exists ? doc.data() : <String, dynamic>{};
      final customOpId = profileData?['operatorId'] as String? ?? auth.user?.operatorId ?? '';

      // Count completed schedules for this operator matching either custom operatorId or UID
      final Set<String> targetIds = {
        uid,
        if (customOpId.isNotEmpty) customOpId,
      };

      int tripsCount = 0;
      final Set<String> seenScheduleIds = {};

      for (final targetId in targetIds) {
        try {
          final snap = await FirebaseFirestore.instance
              .collection('schedules')
              .where('operatorId', isEqualTo: targetId)
              .get();
          for (final sDoc in snap.docs) {
            if (!seenScheduleIds.contains(sDoc.id)) {
              seenScheduleIds.add(sDoc.id);
              final status = sDoc.data()['status'] as String? ?? '';
              if (status == 'completed' || status == 'in_transit' || status == 'active') {
                tripsCount++;
              }
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _operatorProfile = profileData;
          _completedTripsCount = tripsCount > 0 ? tripsCount : (auth.user?.totalRides ?? 0);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _completedTripsCount = auth.user?.totalRides ?? 0;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: 'Edit Profile',
              onPressed: () => _showEditProfileSheet(context, auth, isDark),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : RefreshIndicator(
              onRefresh: _fetchProfile,
              color: AppColors.primaryOrange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(context, auth, isDark),
                    const SizedBox(height: 16),
                    _buildQuickStats(auth, isDark),
                    _buildProfessionalInfo(isDark),
                    _buildSettingsSection(context, settings, auth, isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AuthProvider auth, bool isDark) {
    final profile = _operatorProfile ?? {};
    final name = profile['displayName'] ?? auth.user?.name ?? 'Operator';
    final operatorId = profile['operatorId'] ?? auth.user?.operatorId ?? 'N/A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 40, top: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 70,
                    color: isDark ? Colors.white : AppColors.primaryOrange,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ID: $operatorId',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
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
          _statItem('Rating', auth.user?.rating.toStringAsFixed(1) ?? '5.0', Icons.star, Colors.amber, isDark),
          const SizedBox(width: 12),
          _statItem('Trips', _completedTripsCount.toString(), Icons.route, AppColors.primaryOrange, isDark),
          const SizedBox(width: 12),
          _statItem('Status', 'Active', Icons.verified, Colors.green, isDark),
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
            if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
            Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : AppColors.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfo(bool isDark) {
    final profile = _operatorProfile ?? {};

    final nic = profile['nic'] as String? ?? 'Not provided';
    final phone = profile['phone'] as String? ?? 'Not provided';
    final licenseNumber = profile['licenseNumber'] as String? ?? 'Not set — tap Edit';
    final vehicleAssigned = profile['vehicleAssigned'] as String? ?? 'Not set — tap Edit';
    final company = profile['company'] as String? ?? 'Not set — tap Edit';
    final yearsExp = profile['yearsExperience'];
    final expStr = yearsExp != null ? '$yearsExp years' : 'Not set — tap Edit';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('OPERATOR DETAILS', isDark),
          const SizedBox(height: 12),
          _buildInfoTile(Icons.badge_outlined, 'NIC Number', nic, isDark),
          _buildInfoTile(Icons.phone_outlined, 'Phone', phone, isDark),
          _buildInfoTile(Icons.credit_card_outlined, 'License Number', licenseNumber, isDark, isHighlighted: licenseNumber.contains('tap Edit')),
          _buildInfoTile(Icons.directions_bus_outlined, 'Assigned Vehicle', vehicleAssigned, isDark, isHighlighted: vehicleAssigned.contains('tap Edit')),
          _buildInfoTile(Icons.work_outline, 'Company / Depot', company, isDark, isHighlighted: company.contains('tap Edit')),
          _buildInfoTile(Icons.timer_outlined, 'Experience', expStr, isDark, isHighlighted: expStr.contains('tap Edit')),
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
            ),
          ),
          _buildMenuTile(context, Icons.dark_mode_outlined, Translations.translate(context, 'appearance'), isDark,
            subTitle: _getThemeName(settings.themeMode),
            onTap: () => _showAppearanceDialog(context, settings),
          ),
          _buildMenuTile(context, Icons.language, Translations.translate(context, 'language'), isDark,
            subTitle: settings.selectedLanguage,
            onTap: () => _showLanguageDialog(context, settings),
          ),
          const SizedBox(height: 32),
          CustomButton(
            label: Translations.translate(context, 'logout'),
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

  void _showEditProfileSheet(BuildContext context, AuthProvider auth, bool isDark) {
    final profile = _operatorProfile ?? {};
    final uid = auth.user?.id ?? '';

    final nameC = TextEditingController(text: profile['displayName'] ?? auth.user?.name ?? '');
    final phoneC = TextEditingController(text: profile['phone'] ?? '');
    final licenseC = TextEditingController(text: profile['licenseNumber'] ?? '');
    final vehicleC = TextEditingController(text: profile['vehicleAssigned'] ?? '');
    final companyC = TextEditingController(text: profile['company'] ?? '');
    final expC = TextEditingController(text: profile['yearsExperience']?.toString() ?? '');
    final emergencyC = TextEditingController(text: profile['emergencyContact'] ?? '');

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                        IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _editField(isDark, 'Full Name', Icons.person_outline, nameC),
                    const SizedBox(height: 12),
                    _editField(isDark, 'Phone Number', Icons.phone_outlined, phoneC),
                    const SizedBox(height: 12),
                    _editField(isDark, 'License Number', Icons.credit_card_outlined, licenseC),
                    const SizedBox(height: 12),
                    _editField(isDark, 'Assigned Vehicle', Icons.directions_bus_outlined, vehicleC, hint: 'e.g. NA-4052 (Volvo B11R)'),
                    const SizedBox(height: 12),
                    _editField(isDark, 'Company / Depot', Icons.work_outline, companyC, hint: 'e.g. Intercity Express Ltd.'),
                    const SizedBox(height: 12),
                    _editField(isDark, 'Years of Experience', Icons.timer_outlined, expC, isNumeric: true),
                    const SizedBox(height: 12),
                    _editField(isDark, 'Emergency Contact', Icons.contact_emergency_outlined, emergencyC, hint: 'e.g. +94771234567'),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          if (uid.isEmpty) return;
                          setModal(() => isSaving = true);
                          try {
                            final updates = <String, dynamic>{
                              'displayName': nameC.text.trim(),
                              'phone': phoneC.text.trim(),
                              'updatedAt': FieldValue.serverTimestamp(),
                            };

                            if (licenseC.text.trim().isNotEmpty) updates['licenseNumber'] = licenseC.text.trim();
                            if (vehicleC.text.trim().isNotEmpty) updates['vehicleAssigned'] = vehicleC.text.trim();
                            if (companyC.text.trim().isNotEmpty) updates['company'] = companyC.text.trim();
                            if (expC.text.trim().isNotEmpty) updates['yearsExperience'] = int.tryParse(expC.text.trim()) ?? 0;
                            if (emergencyC.text.trim().isNotEmpty) updates['emergencyContact'] = emergencyC.text.trim();

                            await FirebaseFirestore.instance.collection('operators').doc(uid).set(updates, SetOptions(merge: true));

                            // Refresh auth display name
                            if (nameC.text.trim().isNotEmpty) {
                              await auth.refreshUser();
                            }

                            if (!context.mounted) return;
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(context);
                            await _fetchProfile();

                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            setModal(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _editField(bool isDark, String label, IconData icon, TextEditingController controller, {String? hint, bool isNumeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 13),
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400, fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.primaryOrange, size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5)),
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: isDark ? Colors.white38 : AppColors.textLight.withValues(alpha: 0.6)),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, bool isDark, {bool isHighlighted = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? AppColors.primaryOrange.withValues(alpha: 0.3)
              : (isDark ? Colors.white12 : Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isHighlighted ? AppColors.primaryOrange.withValues(alpha: 0.6) : AppColors.primaryOrange),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : AppColors.textLight)),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isHighlighted
                        ? (isDark ? Colors.white54 : Colors.grey.shade400)
                        : (isDark ? Colors.white : AppColors.textDark),
                    fontSize: isHighlighted ? 13 : 14,
                    fontStyle: isHighlighted ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
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
        title: Text(Translations.translate(context, 'select_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Sinhala', 'Tamil'].map((lang) {
            return ListTile(
              title: Text(lang),
              trailing: settings.selectedLanguage == lang ? const Icon(Icons.check, color: AppColors.primaryOrange) : null,
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
}
