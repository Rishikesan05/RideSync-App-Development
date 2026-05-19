import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';

/// "My Bookings" screen showing past and upcoming trip history
/// from the user's bookings collection in Firestore.
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = auth.user?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookings')),
        body: const Center(child: Text('Please login to view your bookings')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('passengerId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.textLight),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load bookings',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString().contains('index')
                          ? 'Firestore index is being built. Please try again in a few minutes.'
                          : 'Error: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No bookings yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textLight)),
                  const SizedBox(height: 8),
                  const Text('Your trip history will appear here', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                ],
              ),
            );
          }

          // Separate into upcoming and past
          final now = DateTime.now();
          final upcoming = <DocumentSnapshot>[];
          final past = <DocumentSnapshot>[];

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final depTime = data['departureTime'];
            DateTime? departure;
            if (depTime is Timestamp) {
              departure = depTime.toDate();
            }
            if (departure != null && departure.isAfter(now)) {
              upcoming.add(doc);
            } else {
              past.add(doc);
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                _buildSectionHeader('Upcoming Trips', upcoming.length, isDark),
                const SizedBox(height: 12),
                ...upcoming.map((doc) => _buildBookingCard(doc, isDark, isUpcoming: true)),
                const SizedBox(height: 24),
              ],
              if (past.isNotEmpty) ...[
                _buildSectionHeader('Past Trips', past.length, isDark),
                const SizedBox(height: 12),
                ...past.map((doc) => _buildBookingCard(doc, isDark, isUpcoming: false)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, bool isDark) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : AppColors.textDark)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
        ),
      ],
    );
  }

  Widget _buildBookingCard(DocumentSnapshot doc, bool isDark, {required bool isUpcoming}) {
    final data = doc.data() as Map<String, dynamic>;

    final origin = data['origin'] ?? '';
    final destination = data['destination'] ?? '';
    final seats = (data['seats'] as List?)?.join(', ') ?? '';
    final totalFare = (data['totalFare'] ?? 0).toDouble();
    final routeName = data['routeName'] ?? '';
    final plateNumber = data['plateNumber'] ?? '';
    final status = data['status'] ?? 'confirmed';
    final distanceKm = data['distanceKm'] ?? '';

    DateTime? departure;
    final depTime = data['departureTime'];
    if (depTime is Timestamp) {
      departure = depTime.toDate();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUpcoming
              ? AppColors.primaryOrange.withValues(alpha: 0.3)
              : (isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: Route + Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_bus, color: AppColors.primaryOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeName.isNotEmpty ? routeName : '$origin → $destination',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (plateNumber.isNotEmpty)
                      Text(plateNumber, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
              _buildStatusBadge(status, isUpcoming),
            ],
          ),

          const SizedBox(height: 14),

          // Origin → Destination
          if (origin.isNotEmpty && destination.isNotEmpty)
            Row(
              children: [
                Column(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    Container(width: 1, height: 20, color: isDark ? Colors.white10 : Colors.grey.shade300),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(origin, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Text(destination, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),

          const Divider(height: 24),

          // Details row
          Row(
            children: [
              if (departure != null) ...[
                Icon(Icons.calendar_today, size: 13, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(DateFormat('MMM d, hh:mm a').format(departure), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                const SizedBox(width: 16),
              ],
              Icon(Icons.event_seat, size: 13, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(seats, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              if (distanceKm.toString().isNotEmpty) ...[
                const SizedBox(width: 16),
                Icon(Icons.straighten, size: 13, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text('$distanceKm km', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              ],
              const Spacer(),
              Text(
                'LKR ${totalFare.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primaryOrange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isUpcoming) {
    Color bgColor;
    Color textColor;
    String label;

    if (isUpcoming) {
      bgColor = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green;
      label = 'UPCOMING';
    } else {
      switch (status) {
        case 'confirmed':
          bgColor = Colors.blue.withValues(alpha: 0.1);
          textColor = Colors.blue;
          label = 'COMPLETED';
          break;
        case 'cancelled':
          bgColor = Colors.red.withValues(alpha: 0.1);
          textColor = Colors.red;
          label = 'CANCELLED';
          break;
        default:
          bgColor = Colors.grey.withValues(alpha: 0.1);
          textColor = Colors.grey;
          label = status.toUpperCase();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor, letterSpacing: 0.5)),
    );
  }
}
