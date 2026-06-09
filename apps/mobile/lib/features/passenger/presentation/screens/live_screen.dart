import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/live_journey_provider.dart';

/// Live bus tracking screen with simulated bus movement.
/// When an operator shares their live location, this screen will
/// pull real GPS coordinates from Firestore instead of simulation.
class LiveScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const LiveScreen({super.key, this.onBack});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _timer;

  // Simulated route waypoints: Pettah → Town Hall → Borella → Nugegoda → Maharagama → Kaduwela
  final List<LatLng> _routePoints = const [
    LatLng(6.9355, 79.8506),  // Pettah
    LatLng(6.9157, 79.8634),  // Town Hall
    LatLng(6.9108, 79.8746),  // Borella
    LatLng(6.8724, 79.8913),  // Nugegoda
    LatLng(6.8468, 79.9218),  // Maharagama
    LatLng(6.9270, 79.9611),  // Kaduwela
  ];

  int _currentPointIndex = 0;
  LatLng _busPosition = const LatLng(6.9355, 79.8506);
  double _progress = 0;
  String _statusText = 'ON TIME';
  String _nearestHub = 'PETTAH MAIN TERMINAL';
  String _kmToGo = '18.2';
  String _eta = '';
  final bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _eta = _formatETA();
    _startSimulation();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  String _formatETA() {
    final now = DateTime.now();
    final eta = now.add(const Duration(minutes: 35));
    final h = eta.hour > 12 ? eta.hour - 12 : eta.hour;
    final amPm = eta.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')} $amPm';
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isActive || _currentPointIndex >= _routePoints.length - 1) {
        timer.cancel();
        setState(() {
          _statusText = 'ARRIVED';
          _nearestHub = 'KADUWELA EXPRESSWAY';
          _kmToGo = '0.0';
        });
        return;
      }

      _progress += 0.25;
      if (_progress >= 1.0) {
        _progress = 0;
        _currentPointIndex++;
      }

      final from = _routePoints[_currentPointIndex];
      final to = _routePoints[math.min(_currentPointIndex + 1, _routePoints.length - 1)];
      final lat = from.latitude + (to.latitude - from.latitude) * _progress;
      final lng = from.longitude + (to.longitude - from.longitude) * _progress;

      // Calculate remaining distance
      final remaining = (_routePoints.length - 1 - _currentPointIndex) * 4.2 - (_progress * 4.2);

      // Hub names
      const hubNames = [
        'PETTAH MAIN TERMINAL',
        'NEAR TOWN HALL HUB',
        'BORELLA JUNCTION',
        'NUGEGODA BUS STAND',
        'MAHARAGAMA TERMINAL',
        'KADUWELA EXPRESSWAY',
      ];

      if (mounted) {
        setState(() {
          _busPosition = LatLng(lat, lng);
          _kmToGo = remaining.toStringAsFixed(1);
          _nearestHub = hubNames[_currentPointIndex];
          _statusText = 'ON TIME';
        });
      }

      _mapController?.animateCamera(CameraUpdate.newLatLng(_busPosition));
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final liveJourney = context.watch<LiveJourneyProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              const Text('Please log in to view live tracking', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    if (liveJourney.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
      );
    }

    if (!liveJourney.hasActiveBooking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_bus_outlined, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              const Text('You have no active bookings for today.', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    if (!liveJourney.hasJourneyStarted) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule, size: 64, color: AppColors.primaryOrange),
                const SizedBox(height: 24),
                const Text(
                  'Journey Not Started Yet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 12),
                const Text(
                  'When your booked journey starts, the live map will be shared here.',
                  style: TextStyle(color: AppColors.textLight, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Column(
        children: [
          // Top Header Area
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bus, size: 20, color: AppColors.primaryOrange),
                        const SizedBox(width: 8),
                        const Text('Route 154', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.trip_origin, size: 14, color: AppColors.textLight),
                        const SizedBox(width: 6),
                        const Text('Pettah', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_right_alt, size: 18, color: AppColors.textLight),
                        ),
                        const Icon(Icons.location_on, size: 14, color: AppColors.primaryOrange),
                        const SizedBox(width: 4),
                        const Text('Kaduwela', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_pin_circle, size: 14, color: Colors.blueAccent),
                          const SizedBox(width: 6),
                          const Text('Your Stop: Nugegoda', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blueAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      FadeTransition(
                        opacity: _pulseAnimation,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.green, blurRadius: 4, spreadRadius: 1)
                            ]
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('ACTIVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Map and Bottom Card
          Expanded(
            child: Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _busPosition,
                    zoom: 13.5,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: {
                    Marker(
                      markerId: const MarkerId('bus'),
                      position: _busPosition,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                      infoWindow: const InfoWindow(title: 'RS-EX-01', snippet: 'In Transit'),
                    ),
                    // Start marker
                    Marker(
                      markerId: const MarkerId('start'),
                      position: _routePoints.first,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                      infoWindow: const InfoWindow(title: 'Pettah', snippet: 'Start'),
                    ),
                    // End marker
                    Marker(
                      markerId: const MarkerId('end'),
                      position: _routePoints.last,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      infoWindow: const InfoWindow(title: 'Kaduwela', snippet: 'Destination'),
                    ),
                  },
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('route'),
                      color: AppColors.primaryOrange,
                      width: 4,
                      points: _routePoints,
                      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                    ),
                  },
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),

          // Bottom info card (Compact)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16, right: 16, top: 12,
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFFD84315).withValues(alpha: 0.9) : AppColors.primaryOrange.withValues(alpha: 0.9),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distance & Destination
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _kmToGo,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                  const SizedBox(width: 4),
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 2),
                                    child: Text('KM TO GO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
                                  ),
                                ],
                              ),
                              const Text('BOUND FOR: KADUWELA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 0.5)),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.route, color: Colors.white, size: 20),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_currentPointIndex + _progress) / (_routePoints.length - 1),
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ETA & Status
                      Row(
                        children: [
                          _buildInfoTile(
                            'EST. ARRIVAL', 
                            _eta, 
                            Colors.white, 
                            Colors.black54, 
                            Colors.black87,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoTile(
                            'OPTIMIZER', 
                            _statusText, 
                            Colors.white, 
                            Colors.black54, 
                            Colors.green[700]!,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Your Stop ETA
                      Row(
                        children: [
                          _buildInfoTile(
                            'ETA AT YOUR STOP (NUGEGODA)', 
                            '10:15 AM', 
                            Colors.white, 
                            Colors.blueAccent[700]!, 
                            Colors.blueAccent[700]!,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String label, 
    String value, 
    Color bgColor, 
    Color labelColor, 
    Color valueColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: labelColor, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
