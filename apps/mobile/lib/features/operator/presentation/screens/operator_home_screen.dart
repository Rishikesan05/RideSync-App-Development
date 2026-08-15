import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/core/widgets/ridesync_ui.dart';
import 'package:ridesync/core/widgets/notification_tab.dart';
import 'package:ridesync/features/operator/presentation/providers/gps_broadcast_provider.dart';
import 'package:ridesync/features/operator/presentation/screens/operator_navigation_screen.dart';

class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({super.key});

  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _todaySchedules = [];
  Map<String, dynamic>? _activeTrip;

  late AnimationController _animController;
  late AnimationController _radarAnimController;
  final TextEditingController _ticketController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
    _ticketController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchOperatorData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id;
    final operatorId = auth.user?.operatorId ?? userId;
    if (operatorId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = startOfToday.add(const Duration(days: 1));

      // Fetch all schedules for this operator to avoid string vs timestamp and index issues
      final schedulesQuery = await FirebaseFirestore.instance
          .collection('schedules')
          .where('operatorId', isEqualTo: operatorId)
          .get()
          .timeout(const Duration(seconds: 10));

      final docs = schedulesQuery.docs;
      
      List<Map<String, dynamic>> todaySchedules = [];
      for (var doc in docs) {
        final data = doc.data();
        DateTime? depTime;
        final rawTime = data['departureTime'];
        if (rawTime is Timestamp) {
          depTime = rawTime.toDate();
        } else if (rawTime is String) {
          depTime = DateTime.tryParse(rawTime);
        }

        // Filter for today
        if (depTime != null && 
            depTime.isAfter(startOfToday.subtract(const Duration(seconds: 1))) && 
            depTime.isBefore(endOfToday)) {
          final tripData = Map<String, dynamic>.from(data);
          tripData['id'] = doc.id;
          tripData['parsedTime'] = depTime; // For sorting
          todaySchedules.add(tripData);
        }
      }

      // Sort in Dart
      todaySchedules.sort((a, b) {
        final DateTime timeA = a['parsedTime'];
        final DateTime timeB = b['parsedTime'];
        return timeA.compareTo(timeB);
      });

      // Find active trip (first scheduled/active trip today)
      Map<String, dynamic>? activeTrip;
      if (todaySchedules.isNotEmpty) {
        activeTrip = todaySchedules.firstWhere(
          (s) => s['status'] == 'active' || s['status'] == 'scheduled',
          orElse: () => todaySchedules.first,
        );
      }

      if (mounted) {
        setState(() {
          _todaySchedules = todaySchedules;
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
          controller: _scrollController,
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
                          _buildTicketVerification(isDark),
                          const SizedBox(height: AppStyles.sectionSpacing),
                          if (_activeTrip != null) ...[
                            _buildActiveTripCard(_activeTrip!, isDark),
                            const SizedBox(height: AppStyles.sectionSpacing),
                            _buildLiveTrackingMap(isDark),
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

  Widget _buildTicketVerification(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.confirmation_number_outlined, color: AppColors.primaryOrange, size: 24),
              const SizedBox(width: 8),
              Text('Verify Passenger Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
            ]
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ticketController,
                  decoration: InputDecoration(
                    hintText: 'Enter Ticket ID',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.white12 : Colors.grey.shade50,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_ticketController.text.isEmpty) return;
                  _verifyTicket(_ticketController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Verify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTrackingMap(bool isDark) {
    final status = _activeTrip?['status'];
    final isTransit = status == 'active' || status == 'in-transit';
    final gps = context.watch<GpsBroadcastProvider>();
    final speed = gps.currentSpeed;

    return GestureDetector(
      onTap: () {
        if (_activeTrip != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OperatorNavigationScreen(trip: _activeTrip!),
            ),
          );
        }
      },
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(6.9271, 79.8612),
                  zoom: 15,
                ),
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
              ),
              // GPS status pill matching Image 1
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: gps.isBroadcasting ? const Color(0xFFEF4444) : const Color(0xFFEF4444), // Red 'GPS OFF' pill matching image 1
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        gps.isBroadcasting ? 'GPS LIVE' : 'GPS OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Top-right My Location Target button matching Image 1
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.my_location, color: Colors.black80, size: 20),
                ),
              ),
              // Bottom tap invitation bar
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.navigation, color: Color(0xFF2DD4BF), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Tap to open Full Screen Navigation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTripCard(Map<String, dynamic> trip, bool isDark) {
    final routeName = trip['routeName'] ?? 'Jaffna - Colombo';
    final plateNumber = trip['plateNumber'] ?? '';
    final capacity = trip['capacity'] ?? 40;
    final status = trip['status'] ?? 'scheduled';
    final isTransit = status == 'in-transit' || status == 'active';
    final gps = context.watch<GpsBroadcastProvider>();
    final currentSpeed = gps.currentSpeed;
    
    DateTime? departure;
    final depTime = trip['departureTime'];
    if (depTime is Timestamp) {
      departure = depTime.toDate();
    }

    final formattedTime = departure != null ? DateFormat('hh:mm a').format(departure) : '--:--';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527), // Dark navy matching Image 1
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Status Pill Badge & 3-dots Menu Icon (Matching Image 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isTransit ? const Color(0xFF052E16) : Colors.orange.withOpacity(0.2), // Dark green pill background
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isTransit ? const Color(0xFF15803D) : Colors.orange.withOpacity(0.4),
                    ),
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
                              color: Color(0xFF22C55E), // Bright glowing green
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'BROADCASTING GPS',
                          style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'NEXT UP',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  color: const Color(0xFF1E293B),
                  onSelected: (val) {
                    if (val == 'nav') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OperatorNavigationScreen(trip: trip),
                        ),
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'nav',
                      child: Row(
                        children: [
                          Icon(Icons.navigation, color: Color(0xFF2DD4BF), size: 18),
                          SizedBox(width: 8),
                          Text('Open Turn-by-Turn Nav', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Route Name Title (Matching Image 1)
            Text(
              routeName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (plateNumber.isNotEmpty)
              Text(
                plateNumber,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            const SizedBox(height: 20),

            // Occupancy Stepper & Speed Metric Row (Matching Image 1)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Occupancy',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          if (isTransit)
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _updateWalkInCount(trip['id'], -1),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.remove, size: 14, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${24 + (trip['walkInCount'] ?? 0)} / $capacity',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _updateWalkInCount(trip['id'], 1),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              '24 / $capacity',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Green Progress Indicator (Matching Image 1)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (24 + (trip['walkInCount'] ?? 0)) / capacity,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)), // Bright green
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Speedometer Metric Right Side (Matching Image 1)
                Row(
                  children: [
                    const Icon(Icons.speed, color: Color(0xFFF97316), size: 24),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTransit ? '${currentSpeed.toStringAsFixed(0)} km/h' : formattedTime,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          isTransit ? 'Current Speed' : 'Departure',
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            if (isTransit) ...[
              const SizedBox(height: 20),
              // Next Stop Container (Dark nested box matching Image 1)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF172133), // Dark inner card matching Image 1
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFF97316), size: 24), // Orange pin
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Stop: ${trip['currentStop'] ?? 'Vavuniya'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '3 Boarding • 1 Alighting',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _advanceStop(trip['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316), // Orange Arrive button matching Image 1
                        foregroundColor: Colors.white,
                        minimumSize: const Size(64, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Arrive',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Passenger manifest status text (Matching Image 1)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No confirmed passengers yet',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Action Buttons: Delay & End Trip (Matching Image 1)
              Row(
                children: [
                  // Delay button (Gold/Orange Outlined button matching Image 1)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDelayReportModal(trip, isDark),
                      icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
                      label: const Text(
                        'Delay',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF451A03).withOpacity(0.5),
                        side: const BorderSide(color: Color(0xFFD97706), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // End Trip button (Red filled button matching Image 1)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _endJourney(trip['id']),
                      icon: const Icon(Icons.stop_circle, color: Colors.white, size: 18),
                      label: const Text(
                        'End Trip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626), // Red button matching Image 1
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
                    Text('Start Scheduled Journey', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                    IconButton(
                      icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: coOpIdController,
                  decoration: InputDecoration(
                    labelText: 'Enter Co-Operator ID',
                    hintText: 'e.g. RSCOP26-001',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : () async {
                      final enteredId = coOpIdController.text.trim().toUpperCase();
                      if (enteredId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the assigned Co-Operator ID to start')));
                        return;
                      }
                      
                      if (!enteredId.startsWith('RSCOP')) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A Driver (RSCOP format) must be assigned as Co-Operator!')));
                        return;
                      }

                      final scheduledCoOpId = trip['coOperatorId']?.toString().trim().toUpperCase() ?? '';
                      if (scheduledCoOpId.isNotEmpty && enteredId != scheduledCoOpId) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Co-Operator ID does not match the scheduled route!')));
                        return;
                      }

                      setStateModal(() => isSubmitting = true);
                      await _startJourney(trip['id'], '', coOpIdController.text.trim());
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
                        : const Text('Start Journey', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
        Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
        Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Future<void> _verifyTicket(String ticketCode) async {
    try {
      // 1. Find the booking by ticketCode
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('ticketCode', isEqualTo: ticketCode.toUpperCase().trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket not found or invalid'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      final bookingDoc = querySnapshot.docs.first;
      final bookingData = bookingDoc.data();
      final scheduleId = bookingData['scheduleId'];
      final List<dynamic> seats = bookingData['seats'] ?? [];

      if (seats.isEmpty) return;

      // 2. Update the seats to 'boarded' in the schedule's seats subcollection
      final batch = FirebaseFirestore.instance.batch();
      for (final seatNum in seats) {
        final seatRef = FirebaseFirestore.instance
            .collection('schedules')
            .doc(scheduleId)
            .collection('seats')
            .doc(seatNum);
        batch.update(seatRef, {'status': 'boarded', 'updatedAt': FieldValue.serverTimestamp()});
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket $ticketCode verified! ${seats.join(', ')} marked as boarded.'),
            backgroundColor: Colors.green,
          ),
        );
        _ticketController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }



  Future<void> _startJourney(String scheduleId, String coOpName, String coOpId) async {
    try {
      // 1. Start live GPS broadcasting FIRST so a Firestore error never
      //    silently prevents the operator's location from being shared.
      if (!mounted) return;
      final busId = _activeTrip?['busId'] as String? ?? scheduleId;
      final gpsProvider = Provider.of<GpsBroadcastProvider>(context, listen: false);
      final started = await gpsProvider.startBroadcasting(busId);
      if (!started && mounted) {
        // Show a dialog instead of snackbar for GPS failures so the operator
        // can retry without dismissing the start journey flow.
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.gps_off, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text('GPS Broadcast Failed'),
              ],
            ),
            content: Text(
              gpsProvider.errorMessage ?? 'Could not start GPS broadcasting. Please check your location permissions and GPS settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final retryOk = await gpsProvider.startBroadcasting(busId);
                  if (retryOk && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GPS broadcasting started!'), backgroundColor: Colors.green),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }

      // 2. Get the GPS position that was just acquired by the provider
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // 3. Update Firestore schedule status
      final updateData = <String, dynamic>{
        'status': 'in-transit',
        'actualStartTime': FieldValue.serverTimestamp(),
        'startLocationLat': position.latitude,
        'startLocationLng': position.longitude,
      };

      if (coOpName.isNotEmpty || coOpId.isNotEmpty) {
        updateData['coOperatorName'] = coOpName;
        updateData['coOperatorId'] = coOpId;
      }

      await FirebaseFirestore.instance.collection('schedules').doc(scheduleId).update(updateData);

      // 4. Refresh Screen & Navigate to Turn-by-Turn Navigation Screen
      await _fetchOperatorData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journey started! GPS is broadcasting live.'),
            backgroundColor: Colors.green,
          ),
        );

        // Automatically open the Turn-by-Turn Navigation screen matching Image 2
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OperatorNavigationScreen(
              trip: _activeTrip ?? {
                'id': scheduleId,
                'status': 'in-transit',
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start journey: $e')));
      }
    }
  }
  Future<void> _endJourney(String scheduleId) async {
    try {
      // Stop GPS broadcasting first
      final gpsProvider = Provider.of<GpsBroadcastProvider>(context, listen: false);
      await gpsProvider.stopBroadcasting();

      // 1. Mark schedule completed and record actual end time
      await FirebaseFirestore.instance.collection('schedules').doc(scheduleId).update({
        'status': 'completed',
        'actualEndTime': FieldValue.serverTimestamp(),
      });

      // 2. Compute revenue: sum fares from all confirmed bookings for this schedule
      _finalizeRevenue(scheduleId);

      await _fetchOperatorData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip Completed! GPS broadcasting stopped.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /// Non-blocking revenue computation: sums confirmed booking fares and writes
  /// revenue + bookedSeatsCount to the schedule document.
  void _finalizeRevenue(String scheduleId) {
    FirebaseFirestore.instance
        .collection('bookings')
        .where('scheduleId', isEqualTo: scheduleId)
        .where('status', isEqualTo: 'confirmed')
        .get()
        .then((snap) {
      double revenue = 0;
      int bookedSeatsCount = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final fare = data['fare'];
        if (fare is num) revenue += fare.toDouble();
        bookedSeatsCount++;
      }

      return FirebaseFirestore.instance.collection('schedules').doc(scheduleId).update({
        'revenue': revenue,
        'bookedSeatsCount': bookedSeatsCount,
        'revenueComputedAt': FieldValue.serverTimestamp(),
      });
    }).catchError((e) {
      debugPrint('[_finalizeRevenue] Error: $e');
    });
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
      // 1. Fetch the schedule to get routeId and currentStop
      final scheduleDoc = await FirebaseFirestore.instance.collection('schedules').doc(tripId).get();
      if (!scheduleDoc.exists) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule not found.')));
        return;
      }

      final scheduleData = scheduleDoc.data()!;
      final String routeId = scheduleData['routeId'] ?? '';
      final String currentStop = scheduleData['currentStop'] ?? '';

      if (routeId.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No route linked to this schedule.')));
        return;
      }

      // 2. Fetch the route to get the ordered stops list
      final routeDoc = await FirebaseFirestore.instance.collection('routes').doc(routeId).get();
      if (!routeDoc.exists) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Route not found.')));
        return;
      }

      final stops = List<Map<String, dynamic>>.from(
        (routeDoc.data()!['stops'] as List<dynamic>? ?? []).map((s) => Map<String, dynamic>.from(s as Map)),
      );

      if (stops.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No stops defined for this route.')));
        return;
      }

      // 3. Find current stop index and advance to next
      final int currentIdx = stops.indexWhere((s) => s['name'] == currentStop);
      if (currentIdx < 0) {
        // If not found, default to first stop
        await FirebaseFirestore.instance.collection('schedules').doc(tripId).update({
          'currentStop': stops[0]['name'],
        });
      } else if (currentIdx >= stops.length - 1) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Already at final stop!')));
        return;
      } else {
        final String nextStop = stops[currentIdx + 1]['name'] as String;
        await FirebaseFirestore.instance.collection('schedules').doc(tripId).update({
          'currentStop': nextStop,
        });
        await _fetchOperatorData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Arrived at: $nextStop')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update stop: $e')));
    }
  }

  Widget _buildMiniManifest() {
    final tripId = _activeTrip?['id'] as String?;
    if (tripId == null) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('scheduleId', isEqualTo: tripId)
            .where('status', isEqualTo: 'confirmed')
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No confirmed passengers yet',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final seatNo = data['seatNo'] as String? ?? '?';
              final isBoarded = data['boarded'] == true;

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
                      backgroundColor: isBoarded ? Colors.green.shade200 : Colors.orange.shade200,
                      child: Icon(Icons.person, size: 16, color: isBoarded ? Colors.green.shade800 : Colors.orange.shade800),
                    ),
                    const SizedBox(width: 8),
                    Text('Seat $seatNo', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
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
