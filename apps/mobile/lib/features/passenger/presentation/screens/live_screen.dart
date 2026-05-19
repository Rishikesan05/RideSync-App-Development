import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ridesync/core/constants.dart';

/// Live bus tracking screen with simulated bus movement.
/// When an operator shares their live location, this screen will
/// pull real GPS coordinates from Firestore instead of simulation.
class LiveScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const LiveScreen({super.key, this.onBack});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  GoogleMapController? _mapController;
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

      setState(() {
        _busPosition = LatLng(lat, lng);
        _kmToGo = remaining.toStringAsFixed(1);
        _nearestHub = hubNames[_currentPointIndex];
        _statusText = 'ON TIME';
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(_busPosition));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
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

          // Top bar: Hub name + status
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('LIVE SYNC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textLight)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _nearestHub,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                ],
              ),
            ),
          ),

          // Bottom info card (Figma-style)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
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
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(width: 4),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 5),
                                child: Text('KM', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textLight)),
                              ),
                              const SizedBox(width: 4),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 5),
                                child: Text('TO GO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textLight)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text('BOUND FOR: KADUWELA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textLight, letterSpacing: 0.5)),
                        ],
                      ),
                      const Spacer(),
                      Icon(Icons.route, color: AppColors.primaryOrange, size: 28),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (_currentPointIndex + _progress) / (_routePoints.length - 1),
                      minHeight: 6,
                      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ETA & Status
                  Row(
                    children: [
                      _buildInfoTile('EST. ARRIVAL', _eta, isDark),
                      const SizedBox(width: 16),
                      _buildInfoTile('OPTIMIZER', _statusText, isDark, isStatus: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, bool isDark, {bool isStatus = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textLight, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isStatus ? Colors.green : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
