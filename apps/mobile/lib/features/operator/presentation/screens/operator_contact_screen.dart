import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ridesync/core/constants.dart';

class OperatorContactScreen extends StatefulWidget {
  const OperatorContactScreen({super.key});

  @override
  State<OperatorContactScreen> createState() => _OperatorContactScreenState();
}

class _OperatorContactScreenState extends State<OperatorContactScreen> {
  final List<Map<String, dynamic>> _recentTickets = [
    {
      'id': 'TCK-892',
      'title': 'Scanner Not Reading QR Codes',
      'status': 'Pending',
      'date': 'Today, 10:30 AM',
      'type': 'Technical',
    },
    {
      'id': 'TCK-885',
      'title': 'Request Route Change to 120',
      'status': 'Resolved',
      'date': 'Yesterday, 4:15 PM',
      'type': 'Schedule',
    },
    {
      'id': 'TCK-812',
      'title': 'Bus Breakdown at Kadawatha',
      'status': 'Resolved',
      'date': 'June 5, 2026',
      'type': 'Emergency',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
        elevation: 0,
        title: const Text(
          'Contact Admin',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showNewTicketBottomSheet(context, isDark);
        },
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_document),
        label: const Text('New Report', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmergencySection(isDark),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Recent Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
            ),
            const SizedBox(height: 16),
            _buildTicketList(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySection(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.headset_mic_rounded, color: AppColors.primaryOrange, size: 24),
              const SizedBox(width: 12),
              Text('Quick Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.phone_in_talk_rounded,
                  label: 'Call Depot',
                  color: Colors.blue,
                  onTap: () => _launchPhoneCall('+94771234567'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'WhatsApp Admin',
                  color: Colors.green,
                  onTap: () => _launchWhatsApp('+94771234567'),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required MaterialColor color, required VoidCallback onTap, required bool isDark}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.15) : color.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? color.withValues(alpha: 0.3) : color.shade100),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.shade600, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isDark ? color.shade200 : color.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _recentTickets.length,
      itemBuilder: (context, index) {
        final ticket = _recentTickets[index];
        final isResolved = ticket['status'] == 'Resolved';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ticket['type'] == 'Emergency' ? Icons.car_crash_rounded :
                  ticket['type'] == 'Schedule' ? Icons.calendar_month_rounded : Icons.build_circle_rounded,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text('${ticket['id']} • ${ticket['date']}', style: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isResolved ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket['status'],
                  style: TextStyle(
                    color: isResolved ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNewTicketBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Text('Report an Issue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Ticket Subject',
                hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the issue or request in detail...',
                hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add_a_photo_rounded, color: isDark ? Colors.white70 : Colors.grey.shade700),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera opened')));
                    },
                    tooltip: 'Attach Photo',
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.mic_none_rounded, color: isDark ? Colors.white70 : Colors.grey.shade700),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recording voice note...')));
                    },
                    tooltip: 'Record Voice Note',
                  ),
                ),
                const Spacer(),
                Text('Add Attachments', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade500, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully!')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(String phone) async {
    final Uri url = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp. Is it installed?')));
      }
    }
  }

  Future<void> _launchPhoneCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open phone dialer.')));
      }
    }
  }
}
