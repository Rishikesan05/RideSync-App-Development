import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ridesync/core/constants.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Contact Constants
// ─────────────────────────────────────────────────────────────────────────────
const String _kAdminPhone = '+94703753501';     // Admin Depot Hotline
const String _kAdminWhatsApp = '94754918424';   // WhatsApp Number
const String _kWhatsAppMessage = 'Hi I am passenger I need your help';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String get _passengerId {
    return Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
  }

  String get _passengerName {
    return Provider.of<AuthProvider>(context, listen: false).user?.name ?? 'Passenger';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help Center & Support',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.quiz_outlined, size: 20), text: 'FAQs'),
            Tab(icon: Icon(Icons.support_agent_rounded, size: 20), text: 'Contact Admin'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTicketBottomSheet(context, isDark),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('New Inquiry / Report', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqTab(isDark),
          _buildContactAndReportsTab(isDark),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Tab 1: FAQs
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildFaqTab(bool isDark) {
    final List<Map<String, dynamic>> faqCategories = [
      {
        'category': 'Booking & Tickets',
        'icon': Icons.confirmation_number_outlined,
        'color': Colors.blue,
        'items': [
          {
            'q': 'How do I search and book a bus seat?',
            'a': 'Go to the Home screen, select your starting origin and destination, pick a schedule, and tap on available seats. You can then confirm your passenger details and proceed to secure digital payment.'
          },
          {
            'q': 'Where do I find my booked ticket?',
            'a': 'Navigate to your Profile -> "Ride History" or the Bookings tab. Tap any confirmed booking to view the interactive ticket with QR code for boarding.'
          },
          {
            'q': 'Can I book multiple seats at once?',
            'a': 'Yes! On the interactive seat selection layout, you can tap up to 6 available seats simultaneously before proceeding to checkout.'
          },
          {
            'q': 'What happens if I miss my bus?',
            'a': 'Please contact the depot admin immediately using the "Call Depot" or "WhatsApp Admin" button. Depending on route policy, you may be rescheduled to the next available bus.'
          },
        ]
      },
      {
        'category': 'Live Bus Tracking & ETA',
        'icon': Icons.map_outlined,
        'color': Colors.green,
        'items': [
          {
            'q': 'How does real-time bus tracking work?',
            'a': 'When the operator starts their route, their device broadcasts live GPS coordinates directly to our cloud database. The Live map displays the moving bus marker with accurate heading and next-stop indicators.'
          },
          {
            'q': 'What do the pin colors on the map mean?',
            'a': 'Green Pin: Journey Origin.\nRed Pin: Final Destination.\nBlue "YOU" Pin: Your designated boarding stop.\nOrange Numbered Pins: Intermediate boarding and drop-off stations.'
          },
          {
            'q': 'What if the bus location stops moving?',
            'a': 'Temporary GPS signal loss or heavy tunnel traffic may cause delays. If the bus remains stationary for a prolonged time, tap the "Contact Admin" button to report a schedule delay.'
          },
        ]
      },
      {
        'category': 'Payments & Refunds',
        'icon': Icons.payment_outlined,
        'color': Colors.purple,
        'items': [
          {
            'q': 'What payment options are supported?',
            'a': 'RideSync supports Credit / Debit Cards (Visa, Mastercard), Express Digital Checkout, and cash boarding where permitted by the route operator.'
          },
          {
            'q': 'How do I request a cancellation and refund?',
            'a': 'You can submit a refund inquiry through the "New Inquiry / Report" button under the "Contact Admin" tab. Refunds are typically processed within 2–5 business days.'
          },
          {
            'q': 'Is my credit card information secure?',
            'a': 'Yes! RideSync utilizes end-to-end encrypted and tokenized payment channels complying with industry PCI-DSS security standards. We never store your full card CVV.'
          },
        ]
      },
      {
        'category': 'Account & Loyalty Rewards',
        'icon': Icons.card_giftcard_outlined,
        'color': Colors.orange,
        'items': [
          {
            'q': 'How do I earn loyalty points?',
            'a': 'You earn 10 RideSync loyalty points for every completed ride booking. Accumulated points can be redeemed for future ride discounts.'
          },
          {
            'q': 'How do I update my name or phone number?',
            'a': 'Go to My Profile -> Tap your avatar or "Personal Information" under Preferences. Update your full name and phone number and tap Save Changes.'
          },
        ]
      },
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        // Search & Greeting banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            boxShadow: [
              if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.live_help_rounded, color: AppColors.primaryOrange, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'How can we help you?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Browse through our most frequently asked questions or submit an inquiry directly to the RideSync administration team.',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        ...faqCategories.map((cat) {
          final color = cat['color'] as MaterialColor;
          final items = cat['items'] as List<Map<String, String>>;

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(cat['icon'] as IconData, color: color.shade600, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        cat['category'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...items.map((item) {
                  return Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      title: Text(
                        item['q']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.textDark,
                        ),
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item['a']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Tab 2: Contact Admin & My Inquiries
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildContactAndReportsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickContactSection(isDark),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Support Inquiries',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
                onPressed: () => setState(() {}),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap any inquiry to view admin response and status updates',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          _buildPassengerInquiriesList(isDark),
        ],
      ),
    );
  }

  Widget _buildQuickContactSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.headset_mic_rounded, color: AppColors.primaryOrange, size: 24),
              const SizedBox(width: 12),
              Text(
                'Direct Hotline Support',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Need urgent assistance? Reach out to the depot office directly.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500),
          ),
          const SizedBox(height: 18),
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
              const SizedBox(width: 14),
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.12) : color.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? color.withValues(alpha: 0.25) : color.shade100),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? color.withValues(alpha: 0.2) : color.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDark ? color.shade300 : color.shade700, size: 22),
            ),
            const SizedBox(height: 8),
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

  Widget _buildPassengerInquiriesList(bool isDark) {
    if (_passengerId.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            'Please log in to view your support history.',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('passenger_reports')
          .where('passengerId', isEqualTo: _passengerId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Error loading inquiries: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.mark_chat_unread_outlined, size: 48, color: isDark ? Colors.white24 : Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No inquiries submitted yet',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap "New Inquiry / Report" below to send a message to admin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _PassengerInquiryCard(doc: docs[index], isDark: isDark);
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // New Report / Inquiry Bottom Sheet
  // ──────────────────────────────────────────────────────────────────────────

  void _showNewTicketBottomSheet(BuildContext context, bool isDark) {
    String selectedCategory = '🎫 Booking & Ticket Issue';
    final List<String> categories = [
      '🎫 Booking & Ticket Issue',
      '⏱️ Bus Delay / Schedule Issue',
      '💳 Payment & Refund Issue',
      '🧳 Lost & Found',
      '📱 App & Technical Problem',
      '➕ Other Inquiry',
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
                  const SizedBox(height: 20),
                  Text(
                    'Contact Admin / Submit Inquiry',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Our administration team will review and reply to your inquiry shortly.',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500),
                  ),
                  const SizedBox(height: 18),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Inquiry Category',
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: categories
                        .map((String cat) => DropdownMenuItem<String>(
                              value: cat,
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isDark ? Colors.white : AppColors.textDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (String? val) {
                      if (val != null) setModal(() => selectedCategory = val);
                    },
                  ),

                  if (selectedCategory == '➕ Other Inquiry') ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: otherController,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Specify subject/topic...',
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

                  const SizedBox(height: 14),
                  TextField(
                    controller: descController,
                    maxLines: 4,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Describe your issue or question in detail...',
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

                              final pId = _passengerId;
                              if (pId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please log in to submit inquiries.')),
                                );
                                return;
                              }

                              setModal(() => isSubmitting = true);

                              try {
                                final title = selectedCategory == '➕ Other Inquiry'
                                    ? (otherController.text.trim().isEmpty ? 'General Inquiry' : otherController.text.trim())
                                    : selectedCategory;

                                String? fcmToken;
                                try {
                                  fcmToken = await FirebaseMessaging.instance.getToken();
                                } catch (_) {}

                                await FirebaseFirestore.instance.collection('passenger_reports').add({
                                  'passengerId': pId,
                                  'passengerName': _passengerName,
                                  'type': selectedCategory,
                                  'title': title,
                                  'description': desc,
                                  'status': 'pending',
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'fcmToken': fcmToken,
                                });

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Inquiry submitted! Admin will reply shortly.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModal(() => isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to submit: $e'), backgroundColor: Colors.red),
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
                              'Submit Inquiry to Admin',
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
  // Launchers
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _launchWhatsApp() async {
    final encoded = Uri.encodeComponent(_kWhatsAppMessage);
    final nativeUri = Uri.parse('whatsapp://send?phone=$_kAdminWhatsApp&text=$encoded');
    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalNonBrowserApplication);
        return;
      }
    } catch (_) {}

    final webUri = Uri.parse('https://wa.me/$_kAdminWhatsApp?text=$encoded');
    try {
      final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (launched) return;
    } catch (_) {}

    final fallbackUri = Uri.parse('https://api.whatsapp.com/send?phone=$_kAdminWhatsApp&text=$encoded');
    try {
      final launched = await launchUrl(fallbackUri, mode: LaunchMode.platformDefault);
      if (launched) return;
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp. Is it installed?')),
      );
    }
  }

  Future<void> _launchPhoneCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open phone dialer: $e')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Passenger Inquiry Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _PassengerInquiryCard extends StatefulWidget {
  const _PassengerInquiryCard({required this.doc, required this.isDark});

  final QueryDocumentSnapshot doc;
  final bool isDark;

  @override
  State<_PassengerInquiryCard> createState() => _PassengerInquiryCardState();
}

class _PassengerInquiryCardState extends State<_PassengerInquiryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final isDark = widget.isDark;
    final status = data['status'] as String? ?? 'pending';
    final title = data['title'] as String? ?? 'Inquiry';
    final type = data['type'] as String? ?? 'General';
    final description = data['description'] as String? ?? '';
    final adminReply = data['adminReply'] as String?;
    final hasReply = adminReply != null && adminReply.isNotEmpty;

    Color statusColor;
    if (status == 'resolved') {
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
          boxShadow: [
            if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
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
                      _iconForCategory(type),
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
                                      'Replied',
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

            if (_expanded) ...[
              Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description.isNotEmpty) ...[
                      Text(
                        'Your Message',
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
                            Icon(Icons.admin_panel_settings_rounded, size: 16, color: AppColors.primaryOrange),
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
                            'Awaiting admin review...',
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

  IconData _iconForCategory(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('book') || lower.contains('ticket')) return Icons.confirmation_number_outlined;
    if (lower.contains('delay') || lower.contains('schedule')) return Icons.calendar_month_outlined;
    if (lower.contains('pay') || lower.contains('refund')) return Icons.payment_outlined;
    if (lower.contains('lost') || lower.contains('found')) return Icons.luggage_outlined;
    if (lower.contains('app') || lower.contains('tech')) return Icons.build_circle_outlined;
    return Icons.chat_bubble_outline_rounded;
  }

  String _formatStatus(String s) {
    switch (s) {
      case 'pending': return 'Pending';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      default: return s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;
    }
  }
}
