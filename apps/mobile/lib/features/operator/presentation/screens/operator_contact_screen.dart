import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ridesync/core/constants.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin contact constants
// ─────────────────────────────────────────────────────────────────────────────
const String _kAdminPhone = '+94703753501';     // Call Depot number
const String _kAdminWhatsApp = '94754918424';   // WhatsApp number (no +)
const String _kWhatsAppMessage = 'Hi I am operator I need your help';

class OperatorContactScreen extends StatefulWidget {
  const OperatorContactScreen({super.key});

  @override
  State<OperatorContactScreen> createState() => _OperatorContactScreenState();
}

class _OperatorContactScreenState extends State<OperatorContactScreen> {
  String get _operatorId {
    return Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
  }

  String get _operatorName {
    return Provider.of<AuthProvider>(context, listen: false).user?.name ?? 'Operator';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Contact Admin',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTicketBottomSheet(context, isDark),
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
            _buildContactSection(isDark),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Recent Reports',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Tap a report to see admin replies',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 16),
            _buildTicketList(isDark),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Quick Contact Section
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildContactSection(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.headset_mic_rounded, color: AppColors.primaryOrange, size: 24),
              const SizedBox(width: 12),
              Text(
                'Quick Contact',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reach the RideSync admin team instantly',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500),
          ),
          const SizedBox(height: 20),

          // Contact info tiles
          _buildContactInfoTile(
            icon: Icons.phone_in_talk_rounded,
            label: 'Admin Depot Number',
            value: _kAdminPhone,
            color: Colors.blue,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildContactInfoTile(
            icon: Icons.chat_bubble_rounded,
            label: 'Admin WhatsApp',
            value: '+$_kAdminWhatsApp',
            color: Colors.green,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.phone_in_talk_rounded,
                  label: 'Call Depot',
                  sublabel: _kAdminPhone,
                  color: Colors.blue,
                  onTap: () => _launchPhoneCall(_kAdminPhone),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'WhatsApp Admin',
                  sublabel: '+$_kAdminWhatsApp',
                  color: Colors.green,
                  onTap: () => _launchWhatsApp(),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.08) : color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? color.withValues(alpha: 0.2) : color.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: isDark ? color.shade300 : color.shade600, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? color.shade300 : color.shade700,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                )),
              Text(value,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.bold,
                )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String sublabel,
    required MaterialColor color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.15) : color.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? color.withValues(alpha: 0.3) : color.shade100),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? color.withValues(alpha: 0.2) : color.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDark ? color.shade300 : color.shade700, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: isDark ? color.shade200 : color.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                color: isDark ? color.shade400 : color.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Report List
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTicketList(bool isDark) {
    if (_operatorId.isEmpty) {
      return const Center(child: Text('Not authenticated.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('operator_reports')
          .where('operatorId', isEqualTo: _operatorId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Error loading reports: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: isDark ? Colors.white24 : Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'No reports submitted yet.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "New Report" to contact admin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _ReportCard(doc: docs[index], isDark: isDark);
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // New Report Bottom Sheet
  // ──────────────────────────────────────────────────────────────────────────

  void _showNewTicketBottomSheet(BuildContext context, bool isDark) {
    String selectedIssue = '🚍 Bus Breakdown';
    final List<String> issues = [
      '🚍 Bus Breakdown',
      '⏱️ Heavy Traffic / Schedule Delay',
      '👥 Passenger Dispute',
      '📱 App / Tech Issue',
      '➕ Other',
    ];
    final descController = TextEditingController();
    final otherController = TextEditingController();
    bool isSubmitting = false;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Report an Issue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your report will be sent directly to the admin.',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),

                  // Issue type dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedIssue,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: issues
                        .map((String issue) => DropdownMenuItem<String>(
                              value: issue,
                              child: Text(
                                issue,
                                style: TextStyle(
                                  color: isDark ? Colors.white : AppColors.textDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) setModal(() => selectedIssue = newValue);
                    },
                  ),

                  if (selectedIssue == '➕ Other') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: otherController,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Specify reason...',
                        hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 4,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Describe the issue in detail...',
                      hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final desc = descController.text.trim();
                              if (desc.length < 5) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please describe the issue (minimum 5 characters).'),
                                  ),
                                );
                                return;
                              }

                              final operatorId = _operatorId;
                              if (operatorId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Authentication error. Please re-login.')),
                                );
                                return;
                              }

                              setModal(() => isSubmitting = true);

                              try {
                                final type = selectedIssue == '➕ Other'
                                    ? (otherController.text.trim().isEmpty
                                        ? 'Other'
                                        : otherController.text.trim())
                                    : selectedIssue;

                                // Grab the device FCM token so admin can reply to THIS device.
                                String? fcmToken;
                                try {
                                  fcmToken = await FirebaseMessaging.instance.getToken();
                                } catch (_) {}

                                await FirebaseFirestore.instance.collection('operator_reports').add({
                                  'operatorId': operatorId,
                                  'operatorName': _operatorName,
                                  'type': type,
                                  'title': type,
                                  'description': desc,
                                  'status': 'pending',
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'fcmToken': fcmToken,
                                });

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Report submitted! Admin will review shortly.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModal(() => isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to submit report: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primaryOrange.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Submit Report',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // URL launchers
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _launchWhatsApp() async {
    final encoded = Uri.encodeComponent(_kWhatsAppMessage);
    final Uri url = Uri.parse('https://wa.me/$_kAdminWhatsApp?text=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp. Is it installed?')),
        );
      }
    }
  }

  Future<void> _launchPhoneCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer.')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report Card (shows report details + admin reply if present)
// ─────────────────────────────────────────────────────────────────────────────

class _ReportCard extends StatefulWidget {
  const _ReportCard({required this.doc, required this.isDark});

  final QueryDocumentSnapshot doc;
  final bool isDark;

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final isDark = widget.isDark;
    final isResolved = data['status'] == 'resolved';
    final status = data['status'] as String? ?? 'pending';
    final type = data['type'] as String? ?? 'General';
    final title = data['title'] as String? ?? type;
    final description = data['description'] as String? ?? '';
    final adminReply = data['adminReply'] as String?;
    final hasReply = adminReply != null && adminReply.isNotEmpty;

    Color statusColor;
    if (isResolved) {
      statusColor = Colors.green;
    } else if (status == 'in_progress') {
      statusColor = Colors.blue;
    } else {
      statusColor = Colors.orange;
    }

    String dateStr = '';
    if (data['createdAt'] is Timestamp) {
      final dt = (data['createdAt'] as Timestamp).toDate();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        dateStr = 'Today, ${DateFormat('h:mm a').format(dt)}';
      } else if (dt.day == now.day - 1 && dt.month == now.month && dt.year == now.year) {
        dateStr = 'Yesterday, ${DateFormat('h:mm a').format(dt)}';
      } else {
        dateStr = DateFormat('MMM d, y').format(dt);
      }
    }

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasReply
                ? AppColors.primaryOrange.withValues(alpha: 0.5)
                : (isDark ? Colors.white10 : Colors.grey.shade200),
            width: hasReply ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.all(16),
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
                      _iconForType(type),
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : AppColors.textDark,
                                ),
                              ),
                            ),
                            if (hasReply) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.reply, size: 10, color: AppColors.primaryOrange),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Reply',
                                      style: TextStyle(
                                        color: AppColors.primaryOrange,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: isDark ? Colors.white30 : Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatStatus(status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Expanded detail panel
            if (_expanded) ...[
              Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    if (description.isNotEmpty) ...[
                      Text(
                        'Your Report',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : AppColors.textDark,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],

                    // Admin reply
                    if (hasReply) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Admin Reply',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.admin_panel_settings_rounded,
                                size: 16, color: AppColors.primaryOrange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                adminReply,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white : AppColors.textDark,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (data['adminReplyAt'] is Timestamp) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Replied ${DateFormat('MMM d, y · h:mm a').format((data['adminReplyAt'] as Timestamp).toDate())}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white30 : Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ] else ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: isDark ? Colors.white30 : Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Text(
                            'Awaiting admin response...',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white30 : Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('breakdown') || lower.contains('emergency')) return Icons.car_crash_rounded;
    if (lower.contains('schedule') || lower.contains('delay') || lower.contains('traffic')) {
      return Icons.calendar_month_rounded;
    }
    if (lower.contains('tech') || lower.contains('app')) return Icons.build_circle_rounded;
    if (lower.contains('passenger') || lower.contains('dispute')) return Icons.people_alt_rounded;
    return Icons.report_problem_rounded;
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : status;
    }
  }
}
