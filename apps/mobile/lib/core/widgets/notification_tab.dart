import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';

/// Top Notification hub with a real Firestore inbox stream.
class NotificationTab extends StatelessWidget {
  const NotificationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = auth.user?.id;

    if (userId == null) {
      return _buildIconWrapper(context, 0, isDark);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final unreadCount = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return !(data['isRead'] ?? false);
        }).length;

        return _buildIconWrapper(context, unreadCount, isDark, docs: docs);
      },
    );
  }

  Widget _buildIconWrapper(BuildContext context, int unreadCount, bool isDark, {List<QueryDocumentSnapshot>? docs}) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: () => _showNotifications(context, docs ?? []),
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.transparent : Colors.white,
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.notifications_none_outlined,
                size: 20,
                color: isDark ? Colors.white : AppColors.primaryNavy,
              ),
            ),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 2,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF0F172A) : Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotifications(BuildContext context, List<QueryDocumentSnapshot> docs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id;

    // Mark all as read when opening notifications
    if (userId != null && docs.isNotEmpty) {
      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (!(data['isRead'] ?? false)) {
          doc.reference.update({'isRead': true});
        }
      }
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.primaryOrange,
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                  child: docs.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'No notifications yet',
                              style: TextStyle(color: AppColors.textLight, fontSize: 14),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: docs.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            return _NotificationCard(
                              data: data,
                              isDark: isDark,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.data,
    required this.isDark,
  });

  final Map<String, dynamic> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Notification';
    final body = data['body'] ?? '';
    final type = data['type'] ?? 'alert';
    final isRead = data['isRead'] ?? false;
    final isUnread = !isRead;

    // Parse creation date
    String timeLabel = 'Just now';
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) {
        timeLabel = 'Just now';
      } else if (diff.inMinutes < 60) {
        timeLabel = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeLabel = '${diff.inHours}h ago';
      } else {
        timeLabel = DateFormat('MMM d').format(dt);
      }
    }

    // Determine Icon and Accent color based on type
    IconData icon;
    Color accent;
    switch (type) {
      case 'booking':
        icon = Icons.confirmation_number_rounded;
        accent = AppColors.accentBlue;
        break;
      case 'wallet':
        icon = Icons.account_balance_wallet_rounded;
        accent = AppColors.success;
        break;
      case 'notice':
        icon = Icons.campaign_outlined;
        accent = AppColors.primaryNavy;
        break;
      case 'profile':
        icon = Icons.person_outline_rounded;
        accent = AppColors.accentPink;
        break;
      case 'alert':
      default:
        icon = Icons.directions_bus_filled_rounded;
        accent = AppColors.primaryOrange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.primaryOrange.withValues(alpha: 0.08)
            : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnread
              ? AppColors.primaryOrange.withValues(alpha: 0.25)
              : (isDark ? AppColors.strokeDark : AppColors.stroke),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      timeLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
