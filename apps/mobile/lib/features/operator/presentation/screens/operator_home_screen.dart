import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';

class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({super.key});

  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> {
  bool _isLoading = true;
  double _totalRevenue = 0;
  int _tripsToday = 0;
  List<Map<String, dynamic>> _todaySchedules = [];
  Map<String, dynamic>? _activeTrip;

  @override
  void initState() {
    super.initState();
    _fetchOperatorData();
  }

  Future<void> _fetchOperatorData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id;
    if (userId == null) return;

    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = startOfToday.add(const Duration(days: 1));

      // 1. Fetch Revenue from all bookings (filtered by operatorId/system_operator)
      final bookingsQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('operatorId', isEqualTo: 'system_operator')
          .get();

      double revenue = 0;
      for (final doc in bookingsQuery.docs) {
        final data = doc.data();
        revenue += (data['totalFare'] ?? 0).toDouble();
      }

      // 2. Fetch today's schedules
      final schedulesQuery = await FirebaseFirestore.instance
          .collection('schedules')
          .where('operatorId', isEqualTo: 'system_operator')
          .where('departureTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .where('departureTime', isLessThan: Timestamp.fromDate(endOfToday))
          .orderBy('departureTime', descending: false)
          .get();

      List<Map<String, dynamic>> schedules = [];
      for (final doc in schedulesQuery.docs) {
        final data = doc.data();
        schedules.add({
          'id': doc.id,
          ...data,
        });
      }

      // Find active trip (first scheduled/active trip today)
      Map<String, dynamic>? activeTrip;
      if (schedules.isNotEmpty) {
        activeTrip = schedules.firstWhere(
          (s) => s['status'] == 'active' || s['status'] == 'scheduled',
          orElse: () => schedules.first,
        );
      }

      if (mounted) {
        setState(() {
          _totalRevenue = revenue;
          _tripsToday = schedules.length;
          _todaySchedules = schedules;
          _activeTrip = activeTrip;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching operator data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final operatorName = auth.user?.name ?? 'Marcus';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchOperatorData,
          color: AppColors.primaryOrange,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(operatorName, isDark),
                      const SizedBox(height: 24),
                      _buildSummaryCards(isDark),
                      const SizedBox(height: 24),
                      if (_activeTrip != null) ...[
                        _buildActiveTripCard(_activeTrip!, isDark),
                        const SizedBox(height: 24),
                      ],
                      _buildSectionHeader('Today\'s Schedule', isDark),
                      const SizedBox(height: 16),
                      _buildScheduleList(isDark),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bus Operator Dashboard',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryOrange,
              ),
            ),
            Text(
              'Good Morning, $name',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: isDark ? Colors.white10 : AppColors.primaryNavy.withValues(alpha: 0.1),
          child: Icon(Icons.notifications_outlined, color: isDark ? Colors.white : AppColors.primaryNavy),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(bool isDark) {
    return Row(
      children: [
        _statCard('Total Revenue', 'LKR ${_totalRevenue.toStringAsFixed(0)}', Icons.payments_outlined, Colors.green, isDark),
        const SizedBox(width: 16),
        _statCard('Trips Today', '$_tripsToday', Icons.route_outlined, AppColors.primaryOrange, isDark),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTripCard(Map<String, dynamic> trip, bool isDark) {
    final routeName = trip['routeName'] ?? 'Unknown Route';
    final plateNumber = trip['plateNumber'] ?? '';
    final capacity = trip['capacity'] ?? 40;
    
    DateTime? departure;
    final depTime = trip['departureTime'];
    if (depTime is Timestamp) {
      departure = depTime.toDate();
    }

    final formattedTime = departure != null ? DateFormat('hh:mm a').format(departure) : '--:--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryNavy, isDark ? const Color(0xFF1E293B) : const Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trip['status'] == 'active' ? 'ACTIVE NOW' : 'NEXT UP',
                  style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            plateNumber,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            routeName,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _tripMetric(Icons.people_outline, '24/$capacity', 'Occupancy'),
              const SizedBox(width: 24),
              _tripMetric(Icons.timer_outlined, formattedTime, 'Departure'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tripMetric(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleList(bool isDark) {
    if (_todaySchedules.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No trips scheduled for today.',
            style: TextStyle(color: AppColors.textLight),
          ),
        ),
      );
    }

    return Column(
      children: _todaySchedules.map((trip) {
        final dest = trip['routeName']?.split(' - ').last ?? 'Terminal';
        final plate = trip['plateNumber'] ?? '';
        final status = trip['status']?.toUpperCase() ?? 'SCHEDULED';
        
        DateTime? departure;
        final depTime = trip['departureTime'];
        if (depTime is Timestamp) {
          departure = depTime.toDate();
        }
        final formattedTime = departure != null ? DateFormat('hh:mm a').format(departure) : '--:--';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _scheduleItem(dest, formattedTime, plate, status, isDark),
        );
      }).toList(),
    );
  }

  Widget _scheduleItem(String destination, String time, String id, String status, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time, color: AppColors.primaryOrange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To $destination',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
                ),
                Text(
                  'Bus: $id  |  Today at $time',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textLight),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'ACTIVE' 
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: status == 'ACTIVE' ? Colors.green : Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
