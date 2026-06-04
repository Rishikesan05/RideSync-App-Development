import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/core/widgets/ridesync_ui.dart';
import 'package:ridesync/core/widgets/notification_tab.dart';

class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({super.key});

  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  double _totalRevenue = 0;
  int _tripsToday = 0;
  List<Map<String, dynamic>> _todaySchedules = [];
  Map<String, dynamic>? _activeTrip;

  late AnimationController _animController;
  late AnimationController _radarAnimController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _radarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fetchOperatorData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _radarAnimController.dispose();
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
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF0F2F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/logo.jpeg',
                height: 36,
                width: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.directions_bus, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'RideSync Operator',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: const [
          NotificationTab(),
          SizedBox(width: 6),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: _OperatorAccountButton(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOperatorData,
        color: AppColors.primaryOrange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CurvedHeaderText(isDark: isDark, operatorName: operatorName),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          _buildSkeletonLoading(isDark)
                        else ...[
                          _buildSummaryCards(isDark),
                          const SizedBox(height: 18),
                          _buildQuickActions(isDark),
                          const SizedBox(height: AppStyles.sectionSpacing),
                          if (_activeTrip != null) ...[
                            _buildActiveTripCard(_activeTrip!, isDark),
                            const SizedBox(height: AppStyles.sectionSpacing),
                          ],
                          const RideSyncSectionHeader(title: 'Today\'s Schedule'),
                          const SizedBox(height: 16),
                          _buildScheduleList(isDark),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    return RideSyncSurfaceCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RideSyncSectionHeader(title: 'Quick Actions'),
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
      ),
    );
  }

  Widget _quickActionBtn(IconData icon, String label, Color color, bool isDark) {
    return InkWell(
      onTap: () {
        if (label == 'Scan Ticket') {
          _showScanTicketSheet(isDark);
        } else if (label == 'Passengers') {
          _showManifestDialog(isDark);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label Screen Coming Soon')));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                    ? [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)]
                    : [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: isDark ? 0.2 : 0.3)),
              boxShadow: [
                if (!isDark)
                  BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textDark)),
        ],
      ),
    );
  }

  // _buildHeader replaced by _CurvedHeaderText and AppBar

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
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTripCard(Map<String, dynamic> trip, bool isDark) {
    final routeName = trip['routeName'] ?? 'Unknown Route';
    final plateNumber = trip['plateNumber'] ?? '';
    final capacity = trip['capacity'] ?? 40;
    final status = trip['status'] ?? 'scheduled';
    final isTransit = status == 'in-transit' || status == 'active';
    
    DateTime? departure;
    final depTime = trip['departureTime'];
    if (depTime is Timestamp) {
      departure = depTime.toDate();
    }

    final formattedTime = departure != null ? DateFormat('hh:mm a').format(departure) : '--:--';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.primaryNavy),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                        color: isTransit ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isTransit ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isTransit) ...[
                            FadeTransition(
                              opacity: _radarAnimController,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('BROADCASTING GPS', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ] else ...[
                            const Text('NEXT UP', style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ]
                        ]
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
                              if (isTransit) Row(
                                children: [
                                  GestureDetector(onTap: () => _updateWalkInCount(trip['id'], -1), child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.remove, size: 14, color: Colors.white))),
                                  const SizedBox(width: 6),
                                  Text('${24 + (trip['walkInCount'] ?? 0)} / $capacity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(width: 6),
                                  GestureDetector(onTap: () => _updateWalkInCount(trip['id'], 1), child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.add, size: 14, color: Colors.white))),
                                ],
                              ) else
                                Text('24 / $capacity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (24 + (trip['walkInCount'] ?? 0)) / capacity,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(isTransit ? Colors.greenAccent : AppColors.primaryOrange),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    _tripMetric(isTransit ? Icons.speed : Icons.timer_outlined, isTransit ? '42 km/h' : formattedTime, isTransit ? 'Current Speed' : 'Departure'),
                  ],
                ),
                if (isTransit) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primaryOrange, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Next Stop: ${trip['currentStop'] ?? 'Town Hall'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              const Text('3 Boarding • 1 Alighting', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _advanceStop(trip['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(60, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Arrive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMiniManifest(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showDelayReportModal(trip, isDark),
                          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                          label: const Text('Delay', style: TextStyle(color: Colors.white, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.withValues(alpha: 0.3),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.withValues(alpha: 0.5))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _endJourney(trip['id']),
                          icon: const Icon(Icons.stop_circle_outlined, color: Colors.white, size: 18),
                          label: const Text('End Trip', style: TextStyle(color: Colors.white, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (status == 'scheduled') ...[
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
  Future<void> _endJourney(String scheduleId) async {
    try {
      await FirebaseFirestore.instance.collection('schedules').doc(scheduleId).update({
        'status': 'completed',
        'actualEndTime': FieldValue.serverTimestamp(),
      });
      await _fetchOperatorData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip Completed!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showDelayReportModal(Map<String, dynamic> trip, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Report Delay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _delayButton(trip['id'], 5, isDark),
                  _delayButton(trip['id'], 10, isDark),
                  _delayButton(trip['id'], 20, isDark),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _delayButton(String scheduleId, int minutes, bool isDark) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        try {
          await FirebaseFirestore.instance.collection('schedules').doc(scheduleId).update({
            'delayMinutes': FieldValue.increment(minutes),
          });
          await _fetchOperatorData();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $minutes min delay')));
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
        ),
        child: Text('+$minutes m', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18)),
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
      children: List.generate(_todaySchedules.length, (index) {
        final trip = _todaySchedules[index];
        final dest = trip['routeName']?.split(' - ').last ?? 'Terminal';
        final plate = trip['plateNumber'] ?? '';
        final status = trip['status']?.toUpperCase() ?? 'SCHEDULED';
        final isLast = index == _todaySchedules.length - 1;
        
        DateTime? departure;
        final depTime = trip['departureTime'];
        if (depTime is Timestamp) {
          departure = depTime.toDate();
        }
        final formattedTime = departure != null ? DateFormat('hh:mm a').format(departure) : '--:--';

        return _scheduleItem(dest, formattedTime, plate, status, isDark, isLast);
      }),
    );
  }

  Widget _scheduleItem(String destination, String time, String id, String status, bool isDark, bool isLast) {
    return Stack(
      children: [
        if (!isLast)
          Positioned(
            left: 19,
            top: 16,
            bottom: 0,
            child: Container(
              width: 2,
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Center(
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: status == 'ACTIVE' || status == 'IN-TRANSIT' ? Colors.green : AppColors.primaryOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: (status == 'ACTIVE' || status == 'IN-TRANSIT' ? Colors.green : AppColors.primaryOrange).withValues(alpha: 0.5), 
                          blurRadius: 8
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('To $destination', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppColors.textDark)),
                            const SizedBox(height: 4),
                            Text('Bus: $id  •  $time', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textLight)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: status == 'ACTIVE' || status == 'IN-TRANSIT' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(status, style: TextStyle(color: status == 'ACTIVE' || status == 'IN-TRANSIT' ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showScanTicketSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Icon(Icons.qr_code_scanner, size: 64, color: AppColors.primaryOrange),
            const SizedBox(height: 16),
            Text('Scan Passenger Ticket', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
            const SizedBox(height: 12),
            const Text('Camera integration goes here.', style: TextStyle(color: Colors.grey)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManifestDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Passenger Manifest', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
              const SizedBox(height: 16),
              const Text('Full list of passengers for this trip will appear here.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateWalkInCount(String tripId, int delta) async {
    try {
      final tripRef = FirebaseFirestore.instance.collection('schedules').doc(tripId);
      await tripRef.set({
        'walkInCount': FieldValue.increment(delta),
      }, SetOptions(merge: true));
      await _fetchOperatorData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update capacity: $e')));
    }
  }

  Future<void> _advanceStop(String tripId) async {
    try {
      // In a real app, this would advance to the next stop in the route's stop list.
      // We'll just hardcode an update for demonstration.
      await FirebaseFirestore.instance.collection('schedules').doc(tripId).update({
        'currentStop': 'Colombo Fort',
      });
      await _fetchOperatorData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arrived at Next Stop!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update stop: $e')));
    }
  }

  Widget _buildMiniManifest() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isBoarding = index < 3;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isBoarding ? Colors.green.shade200 : Colors.red.shade200,
                  child: Icon(Icons.person, size: 16, color: isBoarding ? Colors.green.shade800 : Colors.red.shade800),
                ),
                const SizedBox(width: 8),
                Text('Passenger ${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CurvedHeaderText extends StatelessWidget {
  const _CurvedHeaderText({required this.isDark, required this.operatorName});
  final bool isDark;
  final String operatorName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Hello,\n$operatorName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 200, end: 0),
                duration: const Duration(milliseconds: 3500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(value, 0),
                    child: child,
                  );
                },
                child: Opacity(
                  opacity: 0.4,
                  child: Image.asset(
                    'assets/images/bussymbol.png',
                    height: 100,
                    color: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
                    colorBlendMode: BlendMode.multiply,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(height: 100, width: 100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Manage your daily routes, coordinate with co-operators, and track your fleet.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatorAccountButton extends StatelessWidget {
  const _OperatorAccountButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showAccountCard(context),
      child: Container(
        width: 44,
        height: 44,
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
            Icons.person_outline_rounded,
            size: 20,
            color: isDark ? Colors.white : AppColors.primaryNavy,
          ),
        ),
      ),
    );
  }

  void _showAccountCard(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = auth.user;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.1),
                child: const Icon(Icons.person, color: AppColors.primaryOrange, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                user?.name ?? 'Operator User',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'Not signed in',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Settings'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (auth.isAuthenticated) {
                          auth.logout();
                          Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
                        } else {
                          Navigator.pushNamed(context, '/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: auth.isAuthenticated ? Colors.redAccent : AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(auth.isAuthenticated ? 'Sign Out' : 'Sign In'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
