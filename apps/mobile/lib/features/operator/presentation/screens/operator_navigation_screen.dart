import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:ridesync/features/operator/presentation/providers/gps_broadcast_provider.dart';
import 'package:ridesync/features/operator/presentation/screens/operator_broadcast_screen.dart';

class OperatorNavigationScreen extends StatefulWidget {
  final Map<String, dynamic> trip;

  const OperatorNavigationScreen({
    super.key,
    required this.trip,
  });

  @override
  State<OperatorNavigationScreen> createState() => _OperatorNavigationScreenState();
}

class _OperatorNavigationScreenState extends State<OperatorNavigationScreen> {
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(6.9271, 79.8612); // Colombo default
  bool _isSoundMuted = false;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  StreamSubscription<Position>? _navPositionSub;

  // Dark navigation map theme style JSON
  static const String _darkMapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#0b1d28"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#7cb7bf"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#0b1d28"}]},
    {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#173b4d"}]},
    {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#0e2a39"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#123b53"}]},
    {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#0a2230"}]},
    {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#1c5678"}]},
    {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#143a4e"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#04141e"}]}
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    _startPositionListening();
    _setupRoutePolyline();
  }

  void _startPositionListening() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );
    _navPositionSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (pos) {
        if (mounted) {
          final newLoc = LatLng(pos.latitude, pos.longitude);
          setState(() {
            _currentLocation = newLoc;
          });
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: newLoc,
                zoom: 17,
                tilt: 45,
                bearing: pos.heading,
              ),
            ),
          );
        }
      },
      onError: (e) => debugPrint('[OperatorNav] Position stream error: $e'),
    );
  }

  @override
  void dispose() {
    _navPositionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentLocation, zoom: 17, tilt: 45),
          ),
        );
      }
    } catch (e) {
      debugPrint('[OperatorNav] Location error: $e');
    }
  }

  void _setupRoutePolyline() {
    // Generate navigation polyline points for route visual
    final startLat = _currentLocation.latitude;
    final startLng = _currentLocation.longitude;
    final points = <LatLng>[
      LatLng(startLat, startLng),
      LatLng(startLat + 0.005, startLng - 0.003),
      LatLng(startLat + 0.012, startLng - 0.008),
      LatLng(startLat + 0.025, startLng - 0.015),
    ];

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('nav_route'),
          points: points,
          color: const Color(0xFF6366F1), // Purple-blue navigation line
          width: 7,
        ),
      );

      // Destination marker
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: points.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: widget.trip['routeName'] ?? 'Destination'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final routeName = widget.trip['routeName'] ?? 'Route';
    final currentStop = widget.trip['currentStop'] ?? 'Next Stop';
    final gpsProvider = context.watch<GpsBroadcastProvider>();
    final speed = gpsProvider.currentSpeed;

    // Calculate estimated arrival time (e.g. + 45 mins)
    final etaTime = DateFormat('HH:mm').format(DateTime.now().add(const Duration(minutes: 45)));

    return Scaffold(
      backgroundColor: const Color(0xFF071822),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // ── 1. Full Screen Google Map (Dark Navigation Theme) ────────────
            GoogleMap(
              style: _darkMapStyle,
              initialCameraPosition: CameraPosition(
                target: _currentLocation,
                zoom: 16,
                tilt: 40,
              ),
              style: _darkMapStyle,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              polylines: _polylines,
              markers: _markers,
            ),

            // ── 2. Top Direction Banner (Dark Teal matching Image 2) ─────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 20,
                  right: 20,
                  bottom: 16,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF034E54), // Teal background matching image 2
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Head west',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text(
                                    'Then ',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Icon(
                                    Icons.turn_right_rounded,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. Right Floating Map Controls (Compass, Search, Sound) ──────
            Positioned(
              right: 16,
              bottom: 180,
              child: Column(
                children: [
                  // Compass N Button
                  _floatingCircleButton(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Text(
                          'N',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          child: Container(
                            width: 3,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _mapController?.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(target: _currentLocation, zoom: 16, tilt: 0, bearing: 0),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Search Button
                  _floatingCircleButton(
                    child: const Icon(Icons.search, color: Colors.white, size: 22),
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  // Sound Mute Toggle Button
                  _floatingCircleButton(
                    child: Icon(
                      _isSoundMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 22,
                    ),
                    onTap: () {
                      setState(() => _isSoundMuted = !_isSoundMuted);
                    },
                  ),
                ],
              ),
            ),

            // ── 4. Bottom-Left Speed Circle Badge ────────────────────────────
            Positioned(
              left: 16,
              bottom: 180,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      speed > 0 ? speed.toStringAsFixed(0) : '--',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'km/h',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 4b. Floating Live Broadcast Button ──────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 152,
              child: Center(
                child: Builder(
                  builder: (context) {
                    final gps = context.watch<GpsBroadcastProvider>();
                    return GestureDetector(
                      onTap: () async {
                        if (gps.isBroadcasting) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OperatorBroadcastScreen(trip: widget.trip),
                            ),
                          );
                        } else {
                          final busId = widget.trip['busId'] as String? ??
                              widget.trip['busPlateNumber'] as String? ??
                              widget.trip['plateNumber'] as String? ??
                              widget.trip['id'] as String;
                          final scheduleId = widget.trip['id'] as String?;
                          final routeId = widget.trip['routeId'] as String?;
                          final ok = await gps.startBroadcasting(
                            busId,
                            scheduleId: scheduleId,
                            routeId: routeId,
                          );
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('GPS broadcasting started!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: gps.isBroadcasting
                              ? const Color(0xFF166534)
                              : const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: (gps.isBroadcasting
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFEF4444))
                                  .withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              gps.isBroadcasting ? Icons.gps_fixed : Icons.gps_off,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              gps.isBroadcasting ? 'GPS LIVE — Tap to manage' : 'Start Live Broadcast',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── 5. Bottom Navigation Control Card (Matching Image 2) ─────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B131F), // Dark navy sheet matching Image 2
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 20, offset: const Offset(0, -4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status / Destination notice line
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFFEF4444), // Red clock icon
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$routeName • Next: $currentStop',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Estimated arrival at $etaTime',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Action buttons row (Exit & Continue matching Image 2)
                    Row(
                      children: [
                        // Exit Button (Black pill with red border and red text)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: Color(0xFFEF4444), size: 18),
                              label: const Text(
                                'Exit',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.black,
                                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Continue Button (Teal filled pill matching Image 2)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _fetchCurrentLocation();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Navigation active. GPS is broadcasting live.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.change_history, color: Color(0xFF071822), size: 18),
                              label: const Text(
                                'Continue',
                                style: TextStyle(
                                  color: Color(0xFF071822),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2DD4BF), // Bright cyan/teal
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _floatingCircleButton({required Widget child, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
