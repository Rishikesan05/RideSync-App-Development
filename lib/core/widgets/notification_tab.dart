import 'package:flutter/material.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/ridesync_ui.dart';

// Top Notification hub with an in-app inbox preview
class NotificationTab extends StatelessWidget {
  const NotificationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((item) => item.isUnread).length;

    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: RideSyncIconCircleButton(
            icon: Icons.notifications_none_outlined,
            onPressed: () => _showNotifications(context),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (context) {
        return RideSyncPopupShell(
          maxHeight: 620,
          child: SizedBox(
            height: 603,
            child: Column(
              children: [
                RideSyncPopupHeader(
                  title: 'Notifications',
                  subtitle:
                      'Recent updates from RideSync and your active trips.',
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('Mark all read'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _InboxFilterChip(
                        label: 'All',
                        selected: true,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _InboxFilterChip(
                        label: 'Trips',
                        selected: false,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _InboxFilterChip(
                        label: 'Payments',
                        selected: false,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return _NotificationCard(
                        item: item,
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
    required this.item,
    required this.isDark,
  });

  final _NotificationItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.isUnread
            ? AppColors.primaryOrange.withValues(alpha: 0.08)
            : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.isUnread
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
              color: item.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.accent, size: 20),
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
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                    if (item.isUnread)
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
                  item.message,
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
                      item.timeLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (item.actionLabel != null)
                      Text(
                        item.actionLabel!,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: item.accent,
                          fontWeight: FontWeight.w800,
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

class _InboxFilterChip extends StatelessWidget {
  const _InboxFilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
  });

  final String label;
  final bool selected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryOrange
            : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected
              ? Colors.white
              : (isDark ? Colors.white : AppColors.textDark),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.icon,
    required this.accent,
    this.actionLabel,
    this.isUnread = false,
  });

  final String title;
  final String message;
  final String timeLabel;
  final IconData icon;
  final Color accent;
  final String? actionLabel;
  final bool isUnread;
}

const List<_NotificationItem> _notifications = [
  _NotificationItem(
    title: 'Boarding starts soon',
    message:
        'Your Pettah to Maharagama ride starts boarding in 12 minutes at Bay 04.',
    timeLabel: 'Just now',
    icon: Icons.directions_bus_filled_rounded,
    accent: AppColors.primaryOrange,
    actionLabel: 'View trip',
    isUnread: true,
  ),
  _NotificationItem(
    title: 'Seat reservation confirmed',
    message:
        'Two seats for your travel squad were locked successfully. Show your pass at entry.',
    timeLabel: '14 mins ago',
    icon: Icons.confirmation_number_rounded,
    accent: AppColors.accentBlue,
    actionLabel: 'Open pass',
    isUnread: true,
  ),
  _NotificationItem(
    title: 'Fare adjustment applied',
    message:
        'A shared-route discount was added to your latest booking. Your updated total is Rs. 750.',
    timeLabel: '1 hr ago',
    icon: Icons.account_balance_wallet_rounded,
    accent: AppColors.success,
    actionLabel: 'See details',
    isUnread: true,
  ),
  _NotificationItem(
    title: 'Service notice',
    message:
        'Colombo Fort departures may run 8 to 10 minutes late due to traffic congestion near Maradana.',
    timeLabel: 'Yesterday',
    icon: Icons.campaign_outlined,
    accent: AppColors.primaryNavy,
    actionLabel: 'Plan alternate',
  ),
  _NotificationItem(
    title: 'Profile reminder',
    message:
        'Add emergency contact details to make assisted travel support faster when needed.',
    timeLabel: '2 days ago',
    icon: Icons.person_outline_rounded,
    accent: AppColors.accentPink,
    actionLabel: 'Update profile',
  ),
];
