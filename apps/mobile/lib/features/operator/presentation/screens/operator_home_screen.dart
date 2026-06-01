import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';

class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({super.key});

  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  double _totalRevenue = 0;
  int _tripsToday = 0;
  List<Map<String, dynamic>> _todaySchedules = [];
  Map<String, dynamic>? _activeTrip;

  late AnimationController _animController;
  late Animation<Color?> _colorAnim1;
  late Animation<Color?> _colorAnim2;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _colorAnim1 = ColorTween(
      begin: AppColors.primaryOrange.withValues(alpha: 0.2),
      end: AppColors.primaryNavy.withValues(alpha: 0.2),
    ).animate(_animController);

    _colorAnim2 = ColorTween(
      begin: AppColors.primaryNavy.withValues(alpha: 0.2),
      end: AppColors.primaryOrange.withValues(alpha: 0.2),
    ).animate(_animController);

    _fetchOperatorData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchOperatorData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = startOfToday.add(const Duration(days: 1));

      // 1. Fetch Revenue from all bookings (filtered by operatorId/system_operator)
      final bookingsQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('operatorId', isEqualTo: 'system_operator')
          .get()
          .timeout(const Duration(seconds: 10));

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
          .get()
          .timeout(const Duration(seconds: 10));

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
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _colorAnim1.value ?? Colors.transparent,
                        (_colorAnim2.value ?? Colors.transparent).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _fetchOperatorData,
              color: AppColors.primaryOrange,
              child: _isLoading
                  ? _buildSkeletonLoading(isDark)
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
                          _buildQuickActions(isDark),
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
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading(bool isDark) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final opacity = 0.4 + (_animController.value * 0.4);
        return Opacity(
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 150, height: 24, color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: Container(height: 100, decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.black12, borderRadius: BorderRadius.circular(20)))),
                    const SizedBox(width: 16),
                    Expanded(child: Container(height: 100, decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.black12, borderRadius: BorderRadius.circular(20)))),
                  ],
                ),
                const SizedBox(height: 24),
                Container(height: 80, decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.black12, borderRadius: BorderRadius.circular(16))),
                const SizedBox(height: 24),
                Container(height: 200, decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.black12, borderRadius: BorderRadius.circular(24))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Actions', isDark),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _quickActionBtn(Icons.qr_code_scanner, 'Scan Ticket', Colors.blue, isDark),
            _quickActionBtn(Icons.groups_outlined, 'Passengers', Colors.purple, isDark),
            _quickActionBtn(Icons.car_crash_outlined, 'Emergency', Colors.red, isDark),
            _quickActionBtn(Icons.assignment_turned_in_outlined, 'Check', Colors.teal, isDark),
          ],
        ),
      ],
    );
  }

  Widget _quickActionBtn(IconData icon, String label, Color color, bool isDark) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label Screen Coming Soon')));
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!isDark)
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : AppColors.textDark)),
        ],
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
    final status = trip['status'] ?? 'scheduled';
    
    DateTime? departure;
    final depTime = trip['departureTime'];
    if (depTime is Timestamp) {
      departure = depTime.toDate();
    }

    final formattedTime = departure != null ? DateFormat('hh:mm a').format(departure) : '--:--';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.primaryNavy.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ColorFilter.mode(Colors.black.withValues(alpha: 0.0), BlendMode.srcOver), // Simple glass effect
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (status == 'active' || status == 'in-transit') ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: (status == 'active' || status == 'in-transit') ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        (status == 'active' || status == 'in-transit') ? 'ACTIVE NOW' : 'NEXT UP',
                        style: TextStyle(
                          color: (status == 'active' || status == 'in-transit') ? Colors.greenAccent : Colors.orangeAccent, 
                          fontSize: 10, 
                          fontWeight: FontWeight.bold
                        ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Occupancy', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('24 / $capacity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: 24 / capacity,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              _tripMetric(Icons.timer_outlined, formattedTime, 'Departure'),
            ],
          ),
          if (status == 'scheduled') ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showStartJourneyModal(trip, isDark),
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text('Start Journey', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
          ),
        ),
      ),
    );
  }

  void _showStartJourneyModal(Map<String, dynamic> trip, bool isDark) {
    final coOpNameController = TextEditingController();
    final coOpIdController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Start Journey', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                    IconButton(
                      icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Read-only Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow('Bus Plate', trip['plateNumber'] ?? 'N/A', isDark),
                      const SizedBox(height: 8),
                      _detailRow('Capacity', '${trip['capacity'] ?? 40} Seats', isDark),
                      const SizedBox(height: 8),
                      _detailRow('Start Time', DateFormat('hh:mm a').format(DateTime.now()), isDark),
                      const SizedBox(height: 8),
                      _detailRow('Location', 'GPS (Auto-detect)', isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form
                Text('Co-Operator Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                const SizedBox(height: 12),
                TextField(
                  controller: coOpNameController,
                  decoration: InputDecoration(
                    labelText: 'Co-Operator Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.black12 : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: coOpIdController,
                  decoration: InputDecoration(
                    labelText: 'Co-Operator ID',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.black12 : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : () async {
                      if (coOpNameController.text.trim().isEmpty || coOpIdController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                        return;
                      }

                      setStateModal(() => isSubmitting = true);
                      await _startJourney(trip['id'], coOpNameController.text.trim(), coOpIdController.text.trim());
                      setStateModal(() => isSubmitting = false);
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Confirm & Start', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
        Text(value, style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Future<void> _startJourney(String scheduleId, String coOpName, String coOpId) async {
    try {
      // 1. Get GPS Location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));

      // 2. Update Firestore
      await FirebaseFirestore.instance.collection('schedules').doc(scheduleId).update({
        'status': 'in-transit',
        'actualStartTime': FieldValue.serverTimestamp(),
        'coOperatorName': coOpName,
        'coOperatorId': coOpId,
        'startLocationLat': position.latitude,
        'startLocationLng': position.longitude,
      });

      // 3. Refresh Screen
      await _fetchOperatorData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Journey started successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start journey: $e')));
      }
    }
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
