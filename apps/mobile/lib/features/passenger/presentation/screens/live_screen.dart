import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/marker_icon_helper.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/live_journey_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/bus_tracking_provider.dart';

/// Live bus tracking screen.
///
/// Subscribes to Firebase Realtime Database via [BusTrackingProvider] and
/// animates the bus marker smoothly between coordinate updates.
///
/// Data flow:
///   1. [LiveJourneyProvider] finds the passenger's active booking + scheduleId.
///   2. This screen fetches the schedule doc to get busId + route details.
///   3. [BusTrackingProvider.startTracking(busId, scheduleId)] opens RTDB streams.
///   4. Every new [BusLocation] triggers marker animation.
class LiveScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const LiveScreen({super.key, this.onBack});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen>
    with TickerProviderStateMixin {
  // ── Map controller ──────────────────────────────────────────────────────────
  GoogleMapController? _mapController;

  // ── Pulse animation for the "ACTIVE" badge ──────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Marker interpolation (Hardware-accelerated 60fps AnimationController) ──
  late AnimationController _markerAnimController;
  LatLng? _displayPosition;
  double _displayHeading = 0.0;
  LatLng? _fromPosition;
  LatLng? _toPosition;
  double _fromHeading = 0.0;
  double _toHeading = 0.0;

  // ── Custom Marker Icons ─────────────────────────────────────────────────────
  BitmapDescriptor? _busMarkerIcon;

  // ── Schedule/route details (fetched once from Firestore) ────────────────────
  String? _busId;
  String? _routeName;
  String? _fromStop;
  String? _toStop;
  String? _passengerStop; // passenger's boarding stop
  bool _isFetchingSchedule = false;
  String? _fetchError;

  // ── Route polyline + stop markers ───────────────────────────────────────────
  Set<Polyline> _routePolylines = {};
  Set<Marker> _stopMarkers = {};
  List<LatLng> _routePoints = [];

  // ── Stale-signal warning timer ──────────────────────────────────────────────
  Timer? _staleCheckTimer;

  @override
  void initState() {
    super.initState();

    _loadCustomIcons();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Hardware-accelerated marker translation animation
    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _markerAnimController.addListener(() {
      if (_fromPosition != null && _toPosition != null) {
        final t = Curves.easeInOut.transform(_markerAnimController.value);
        final lat = _fromPosition!.latitude + (_toPosition!.latitude - _fromPosition!.latitude) * t;
        final lng = _fromPosition!.longitude + (_toPosition!.longitude - _fromPosition!.longitude) * t;
        final heading = _fromHeading + (_toHeading - _fromHeading) * t;

        if (mounted) {
          setState(() {
            _displayPosition = LatLng(lat, lng);
            _displayHeading = heading;
          });
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(_displayPosition!),
          );
        }
      }
    });

    // Fetch schedule once providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTracking();
    });
  }

  Future<void> _loadCustomIcons() async {
    try {
      final busIcon = await MarkerIconHelper.createBusMarker();
      if (mounted) {
        setState(() {
          _busMarkerIcon = busIcon;
        });
      }
    } catch (e) {
      debugPrint('[LiveScreen] Error generating bus icon: $e');
    }
  }

  // ── Initialise tracking ─────────────────────────────────────────────────────

  Future<void> _initTracking() async {
    final liveJourney = context.read<LiveJourneyProvider>();
    final tracking = context.read<BusTrackingProvider>();

    // Already initialised (e.g. hot-reload)
    if (_busId != null) return;

    // We need a confirmed booking to know which bus to track
    if (!liveJourney.hasActiveBooking) return;

    // Find the nearest active/upcoming confirmed booking for this user
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;

    setState(() => _isFetchingSchedule = true);

    try {
      final bookingSnap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('passengerId', isEqualTo: userId)
          .get();

      if (bookingSnap.docs.isEmpty) {
        setState(() {
          _isFetchingSchedule = false;
          _fetchError = 'No bookings found. Book a bus to access live tracking.';
        });
        return;
      }

      final allBookings = bookingSnap.docs
          .map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          })
          .where((b) =>
              b['status'] != 'cancelled' &&
              b['status'] != 'completed' &&
              (b['busId'] != null || b['scheduleId'] != null))
          .toList();

      if (allBookings.isEmpty) {
        setState(() {
          _isFetchingSchedule = false;
          _fetchError = 'No active trip in progress. Your next booked journey will appear here once the operator begins the trip.';
        });
        return;
      }

      // Sort newest first
      allBookings.sort((a, b) {
        final timeA = a['departureTime'] ?? a['timestamp'];
        final timeB = b['departureTime'] ?? b['timestamp'];
        if (timeA == null || timeB == null) return 0;
        return timeB.toString().compareTo(timeA.toString());
      });

      // Find active in-transit trip first, or latest upcoming non-completed trip
      Map<String, dynamic>? selectedBooking;
      DocumentSnapshot<Map<String, dynamic>>? selectedScheduleDoc;

      for (final b in allBookings) {
        final schedId = b['scheduleId'] as String?;
        if (schedId != null) {
          try {
            final sDoc = await FirebaseFirestore.instance
                .collection('schedules')
                .doc(schedId)
                .get();
            if (sDoc.exists) {
              final sStatus = sDoc.data()?['status'] as String?;
              if (sStatus == 'in-transit' || sStatus == 'started') {
                selectedBooking = b;
                selectedScheduleDoc = sDoc;
                break;
              } else if (sStatus != 'completed' && sStatus != 'cancelled') {
                if (selectedBooking == null) {
                  selectedBooking = b;
                  selectedScheduleDoc = sDoc;
                }
              }
            }
          } catch (_) {}
        } else if (b['busId'] != null) {
          selectedBooking ??= b;
        }
      }

      if (selectedBooking == null) {
        setState(() {
          _isFetchingSchedule = false;
          _fetchError = 'No active trip in progress. Your next booked journey will appear here once the operator begins the trip.';
        });
        return;
      }

      final bookingData = selectedBooking;
      final scheduleId = bookingData['scheduleId'] as String?;
      final directBusId = bookingData['busId'] as String?;
      _passengerStop = (bookingData['pickup'] as String?) ?? (bookingData['origin'] as String?);
      final origin = bookingData['origin'] as String?;
      final destination = bookingData['destination'] as String?;

      if (scheduleId == null && directBusId != null) {
        // Direct bus booking without schedule document (matching Firestore bookings schema)
        setState(() {
          _busId = directBusId;
          _routeName = origin != null && destination != null ? '$origin - $destination' : 'Live Bus';
          _fromStop = origin ?? 'Origin';
          _toStop = destination ?? 'Destination';
          _isFetchingSchedule = false;
        });

        tracking.startTracking(directBusId, directBusId);
        _startStaleCheckTimer();
        return;
      }

      if (scheduleId == null && directBusId == null) {
        setState(() {
          _isFetchingSchedule = false;
          _fetchError = 'Booking has no bus or schedule linked.';
        });
        return;
      }

      // Read the fetched schedule to get busId and route info
      final scheduleDoc = selectedScheduleDoc ??
          await FirebaseFirestore.instance
              .collection('schedules')
              .doc(scheduleId!)
              .get();

      String busId = directBusId ?? scheduleId!;
      if (scheduleDoc.exists) {
        final sd = scheduleDoc.data()!;
        busId = (sd['busId'] as String?) ??
            (sd['busPlateNumber'] as String?) ??
            (sd['plateNumber'] as String?) ??
            directBusId ??
            scheduleId!;
        setState(() {
          _routeName = (sd['routeName'] as String?) ?? (origin != null && destination != null ? '$origin - $destination' : 'Live Bus');
          _fromStop = (sd['fromStop'] as String?) ?? (sd['startingPoint'] as String?) ?? origin ?? '—';
          _toStop = (sd['toStop'] as String?) ?? destination ?? '—';
        });
        final routeId = (sd['routeId'] as String?) ?? (bookingData['routeId'] as String?);
        if (routeId != null) {
          _fetchRoutePolyline(routeId);
        }
      } else {
        setState(() {
          _routeName = origin != null && destination != null ? '$origin - $destination' : 'Live Bus';
          _fromStop = origin ?? '—';
          _toStop = destination ?? '—';
        });
        final routeId = bookingData['routeId'] as String?;
        if (routeId != null) {
          _fetchRoutePolyline(routeId);
        }
      }

      setState(() {
        _busId = busId;
        _isFetchingSchedule = false;
      });

      // Start RTDB subscriptions
      if (busId.isNotEmpty) {
        tracking.startTracking(busId, scheduleId ?? busId);
        _startStaleCheckTimer();
      }
    } catch (e) {
      debugPrint('[LiveScreen] Init error: $e');
      if (mounted) {
        setState(() {
          _isFetchingSchedule = false;
          _fetchError = 'Failed to load tracking data: $e';
        });
      }
    }
  }

  // ── Stale check timer ────────────────────────────────────────────────────────

  void _startStaleCheckTimer() {
    _staleCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {}); // rebuild so isStale check re-evaluates
    });
  }

  // ── Route polyline + stop markers ───────────────────────────────────────────

  /// Fetches route stops from Firestore and geocodes each stop name to
  /// lat/lng. Draws high-visibility dual polylines connecting all stops and places
  /// custom-designed stop markers (Origin, Your Stop, Intermediate, Destination).
  Future<void> _fetchRoutePolyline(String routeId) async {
    try {
      final routeDoc = await FirebaseFirestore.instance
          .collection('routes')
          .doc(routeId)
          .get();
      if (!routeDoc.exists || !mounted) return;

      final stops = (routeDoc.data()?['stops'] as List<dynamic>?) ?? [];
      if (stops.isEmpty) return;

      final List<LatLng> polylinePoints = [];
      final Set<Marker> stopMarkers = {};

      for (int i = 0; i < stops.length; i++) {
        final stopName = (stops[i]['name'] as String? ?? '').split(',')[0].trim();
        if (stopName.isEmpty) continue;

        try {
          LatLng? latLng;
          if (stops[i]['lat'] != null && stops[i]['lng'] != null) {
            latLng = LatLng(
              (stops[i]['lat'] as num).toDouble(),
              (stops[i]['lng'] as num).toDouble(),
            );
          } else {
            final locations = await locationFromAddress('$stopName, Sri Lanka');
            if (locations.isNotEmpty) {
              latLng = LatLng(locations.first.latitude, locations.first.longitude);
            }
          }
          if (latLng == null) continue;

          polylinePoints.add(latLng);

          // Determine marker type
          final isPassengerStop = _passengerStop != null &&
              _passengerStop!.isNotEmpty &&
              (stopName.toLowerCase().contains(_passengerStop!.toLowerCase()) ||
               _passengerStop!.toLowerCase().contains(stopName.toLowerCase()));

          final StopMarkerType markerType;
          if (isPassengerStop) {
            markerType = StopMarkerType.passengerStop;
          } else if (i == 0) {
            markerType = StopMarkerType.origin;
          } else if (i == stops.length - 1) {
            markerType = StopMarkerType.destination;
          } else {
            markerType = StopMarkerType.intermediate;
          }

          final stopIcon = await MarkerIconHelper.createStopMarker(
            type: markerType,
            stopNumber: '${i + 1}',
            size: isPassengerStop ? 96 : 82,
          );

          stopMarkers.add(
            Marker(
              markerId: MarkerId('stop_$i'),
              position: latLng,
              icon: stopIcon,
              anchor: const Offset(0.5, 0.95),
              infoWindow: InfoWindow(
                title: isPassengerStop ? 'Your Boarding Stop: $stopName' : stopName,
                snippet: i == 0
                    ? 'Route Origin'
                    : i == stops.length - 1
                        ? 'Final Destination'
                        : isPassengerStop ? 'Your designated boarding hub' : 'Stop ${i + 1}',
              ),
              zIndexInt: isPassengerStop ? 5 : 1,
            ),
          );
        } catch (geocodeErr) {
          debugPrint('[LiveScreen] Geocode failed for "$stopName": $geocodeErr');
        }
      }

      if (!mounted) return;
      setState(() {
        _routePoints = polylinePoints;
        _routePolylines = polylinePoints.length >= 2
            ? {
                // 1. Dark casing for sharp contrast over maps
                Polyline(
                  polylineId: const PolylineId('route_casing'),
                  points: polylinePoints,
                  color: const Color(0xFF9A3412),
                  width: 7,
                  jointType: JointType.round,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                ),
                // 2. Core vibrant active route line
                Polyline(
                  polylineId: const PolylineId('route_core'),
                  points: polylinePoints,
                  color: AppColors.primaryOrange,
                  width: 4,
                  jointType: JointType.round,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                ),
              }
            : {};
        _stopMarkers = stopMarkers;
      });
    } catch (e) {
      debugPrint('[LiveScreen] _fetchRoutePolyline error: $e');
    }
  }

  // ── Camera Helpers ──────────────────────────────────────────────────────────

  void _recenterOnBus() {
    if (_displayPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _displayPosition!,
            zoom: 16,
            bearing: _displayHeading,
            tilt: 25,
          ),
        ),
      );
    }
  }

  void _fitRouteBounds() {
    final points = <LatLng>[
      ?_displayPosition,
      ..._routePoints,
    ];
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 64),
    );
  }

  // ── Marker animation ─────────────────────────────────────────────────────────

  /// Called every time [BusTrackingProvider] emits a new location.
  void _animateMarkerTo(LatLng target, double targetHeading) {
    if (_displayPosition == null) {
      setState(() {
        _displayPosition = target;
        _displayHeading = targetHeading;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(target));
      return;
    }

    _fromPosition = _displayPosition;
    _toPosition = target;
    _fromHeading = _displayHeading;
    _toHeading = targetHeading;

    _markerAnimController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _markerAnimController.dispose();
    _staleCheckTimer?.cancel();
    _mapController?.dispose();
    // Stop RTDB subscriptions when leaving the screen
    context.read<BusTrackingProvider>().stopTracking();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final liveJourney = context.watch<LiveJourneyProvider>();
    final tracking = context.watch<BusTrackingProvider>();

    // — Auth gate —
    if (!auth.isAuthenticated) {
      return _buildGate(
        icon: Icons.lock_outline,
        message: 'Please log in to view live tracking.',
      );
    }

    // — Loading states —
    if (liveJourney.isLoading || _isFetchingSchedule) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
      );
    }

    if (_fetchError != null) {
      return _buildGate(icon: Icons.error_outline, message: _fetchError!);
    }

    // — No active booking —
    if (!liveJourney.hasActiveBooking) {
      return _buildGate(
        icon: Icons.directions_bus_outlined,
        message: 'You have no active bookings for today.',
      );
    }

    // — Journey not started —
    if (!liveJourney.hasJourneyStarted) {
      return _buildGate(
        icon: Icons.schedule,
        message: 'When your booked journey starts, the live map will appear here.',
        iconColor: AppColors.primaryOrange,
      );
    }

    // — Bus ID not resolved yet —
    if (_busId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
      );
    }

    // — Animate marker smoothly when a new location arrives —
    if (tracking.busLocation != null) {
      final newPos = tracking.busLocation!.latLng;
      final newHeading = tracking.busLocation!.heading;
      if (_displayPosition == null) {
        _displayPosition = newPos;
        _displayHeading = newHeading;
      } else if (_toPosition != newPos) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animateMarkerTo(newPos, newHeading);
        });
      }
    }

    final busLoc = tracking.busLocation;
    final tripStatus = tracking.tripStatus;
    final isStale = tracking.isStale;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Column(
        children: [
          _buildHeader(isDark, busLoc, tripStatus, isStale),
          Expanded(
            child: Stack(
              children: [
                _buildMap(isDark, busLoc),
                if (isStale) _buildStaleWarning(),
                _buildBottomCard(isDark, busLoc, tripStatus),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────────

  Widget _buildGate({required IconData icon, required String message, Color? iconColor}) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: iconColor ?? AppColors.textLight),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, BusLocation? busLoc, TripStatus? tripStatus, bool isStale) {
    final routeLabel = _routeName ?? 'Live Tracking';
    final fromLabel = _fromStop ?? '—';
    final toLabel = _toStop ?? '—';

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                  Text(routeLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.trip_origin, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Text(fromLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_right_alt, size: 18, color: AppColors.textLight),
                  ),
                  const Icon(Icons.location_on, size: 14, color: AppColors.primaryOrange),
                  const SizedBox(width: 4),
                  Text(toLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              if (_passengerStop != null) ...[
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
                      Text(
                        'Your Stop: $_passengerStop',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isStale
                  ? Colors.orange.withValues(alpha: 0.15)
                  : Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                FadeTransition(
                  opacity: _pulseAnimation,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: isStale ? Colors.orange : Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isStale ? Colors.orange : Colors.green,
                          blurRadius: 4, spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isStale ? 'DELAYED' : 'LIVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isStale ? Colors.orange : Colors.green,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(bool isDark, BusLocation? busLoc) {
    final center = _displayPosition ?? const LatLng(7.8731, 80.7718);

    // Merge the bus marker with the custom stop markers
    final Set<Marker> allMarkers = {..._stopMarkers};
    if (_displayPosition != null) {
      allMarkers.add(
        Marker(
          markerId: const MarkerId('bus'),
          position: _displayPosition!,
          icon: _busMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: _routeName ?? 'Live Bus',
            snippet: busLoc != null
                ? '${busLoc.speed.toStringAsFixed(0)} km/h • In Transit'
                : 'Live Tracking',
          ),
          rotation: _displayHeading,
          flat: true,
          zIndexInt: 10, // Render bus on top of stop markers
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: center, zoom: 14),
          onMapCreated: (controller) {
            _mapController = controller;
            // Auto fit route if stops are ready
            if (_routePoints.isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 600), _fitRouteBounds);
            }
          },
          markers: allMarkers,
          polylines: _routePolylines,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          myLocationEnabled: true,
        ),

        // Floating Map Controls (Recenter on Bus + Fit Route Bounds + Zoom)
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recenter on Live Bus
              _mapActionButton(
                icon: Icons.directions_bus_rounded,
                tooltip: 'Focus Bus',
                isDark: isDark,
                onTap: _recenterOnBus,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(height: 10),
              // Fit Full Route Bounds
              _mapActionButton(
                icon: Icons.route_rounded,
                tooltip: 'Fit Route',
                isDark: isDark,
                onTap: _fitRouteBounds,
              ),
              const SizedBox(height: 10),
              // Zoom In
              _mapActionButton(
                icon: Icons.add,
                tooltip: 'Zoom In',
                isDark: isDark,
                onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
              ),
              const SizedBox(height: 6),
              // Zoom Out
              _mapActionButton(
                icon: Icons.remove,
                tooltip: 'Zoom Out',
                isDark: isDark,
                onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mapActionButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: color ?? (isDark ? Colors.white : AppColors.textDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaleWarning() {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.shade700,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.signal_wifi_statusbar_connected_no_internet_4, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Location signal lost — last known position shown',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCard(bool isDark, BusLocation? busLoc, TripStatus? tripStatus) {
    final eta = tripStatus?.etaFormatted ?? '--:--';
    final currentStop = tripStatus?.currentStop ?? '—';
    final speed = busLoc != null ? '${busLoc.speed.toStringAsFixed(0)} km/h' : '—';
    final delayMin = tripStatus?.delayMinutes ?? 0;
    final statusText = delayMin > 0 ? '${delayMin}m DELAY' : 'ON TIME';
    final statusColor = delayMin > 0 ? Colors.orange : Colors.greenAccent;

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFFD84315) : AppColors.primaryOrange)
                  .withValues(alpha: 0.92),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current stop row
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Now at: $currentStop',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Info tiles row
                Row(
                  children: [
                    _infoTile('EST. ARRIVAL', eta, Colors.white, Colors.black54, Colors.black87),
                    const SizedBox(width: 8),
                    _infoTile('STATUS', statusText, Colors.white, Colors.black54, statusColor),
                    const SizedBox(width: 8),
                    _infoTile('SPEED', speed, Colors.white, Colors.black54, Colors.black87),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, Color bg, Color labelColor, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: labelColor, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: valueColor)),
          ],
        ),
      ),
    );
  }
}
