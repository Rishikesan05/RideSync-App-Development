import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/operator/presentation/providers/gps_broadcast_provider.dart';

/// Dedicated GPS Broadcast Screen for the Operator.
///
/// Matches the Beep-app reference UI:
///   - Route header (routeName, plateNumber) + Bus / Train vehicle toggle.
///   - Full-screen Google Map showing the operator's current location.
///   - Prominent bottom CTA: "Start Live Location Sharing" (orange) /
///     "Stop Live Location Sharing" (red).
///
/// Navigation:
///   Opened via a "Live Broadcast" button inside [OperatorNavigationScreen]
///   so the operator can access the dedicated broadcast toggle any time
///   while the full-screen navigation map is active.
///
/// State is read from [GpsBroadcastProvider] which is already registered
/// in the root [MultiProvider] in `main.dart`.
class OperatorBroadcastScreen extends StatefulWidget {
  final Map<String, dynamic> trip;

  const OperatorBroadcastScreen({super.key, required this.trip});

  @override
  State<OperatorBroadcastScreen> createState() =>
      _OperatorBroadcastScreenState();
}

class _OperatorBroadcastScreenState extends State<OperatorBroadcastScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;

  // Vehicle mode toggle: 0 = Bus, 1 = Train
  int _vehicleMode = 0;

  // Pulse animation for the live broadcasting indicator dot
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String get _routeName => widget.trip['routeName'] as String? ?? 'Route';
  String get _plateNumber => widget.trip['plateNumber'] as String? ?? '';
  String get _busId => widget.trip['busId'] as String? ?? '';
  String? get _scheduleId => widget.trip['id'] as String?;
  String? get _routeId => widget.trip['routeId'] as String?;

  Future<void> _toggleBroadcast(GpsBroadcastProvider gps) async {
    if (gps.isBroadcasting) {
      await gps.stopBroadcasting();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live location sharing stopped.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (_busId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No bus assigned to this trip. Cannot broadcast.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final ok = await gps.startBroadcasting(
        _busId,
        scheduleId: _scheduleId,
        routeId: _routeId,
        busPlateNumber: _plateNumber.isNotEmpty ? _plateNumber : null,
        routeName: _routeName != 'Route' ? _routeName : null,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(gps.errorMessage ?? 'Failed to start GPS.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live location sharing started!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gps = context.watch<GpsBroadcastProvider>();
    final isBroadcasting = gps.isBroadcasting;
    final speed = gps.currentSpeed;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top App Bar ──────────────────────────────────────────────────
            _buildAppBar(),

            // ── Route Header ─────────────────────────────────────────────────
            _buildRouteHeader(isBroadcasting, speed),

            // ── Vehicle Mode Selector ────────────────────────────────────────
            _buildVehicleModeSelector(),

            // ── Select Bus label ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Bus',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // ── Bus info chip ────────────────────────────────────────────────
            _buildBusChip(),

            // ── Map ──────────────────────────────────────────────────────────
            Expanded(child: _buildMap(isBroadcasting)),

            // ── Bottom CTA button ─────────────────────────────────────────────
            _buildBroadcastButton(gps, isBroadcasting),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const Spacer(),
          // RideSync branding
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.directions_bus, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 6),
              const Text(
                'RideSync',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Grid / settings icon placeholder
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteHeader(bool isBroadcasting, double speed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_bus, color: AppColors.primaryOrange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _routeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_plateNumber.isNotEmpty)
                  Text(
                    _plateNumber,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          // Live badge + speed
          if (isBroadcasting)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _pulseAnimation,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${speed.toStringAsFixed(0)} km/h',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleModeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            _vehicleTab(0, Icons.directions_bus_rounded, 'Bus'),
            _vehicleTab(1, Icons.train_rounded, 'Train'),
          ],
        ),
      ),
    );
  }

  Widget _vehicleTab(int index, IconData icon, String label) {
    final isSelected = _vehicleMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _vehicleMode = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.white38),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusChip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_bus_rounded,
              color: AppColors.primaryOrange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _routeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _plateNumber.isNotEmpty ? _plateNumber : '—',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down,
              color: Colors.white54, size: 20),
        ],
      ),
    );
  }

  Widget _buildMap(bool isBroadcasting) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(6.9271, 79.8612), // Colombo default
            zoom: 15,
          ),
          onMapCreated: (ctrl) => _mapController = ctrl,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
        ),

        // Zoom controls (+ / -)
        Positioned(
          left: 12,
          bottom: 16,
          child: Column(
            children: [
              _mapControl(
                Icons.add,
                () => _mapController?.animateCamera(
                  CameraUpdate.zoomIn(),
                ),
              ),
              const SizedBox(height: 8),
              _mapControl(
                Icons.remove,
                () => _mapController?.animateCamera(
                  CameraUpdate.zoomOut(),
                ),
              ),
            ],
          ),
        ),

        // GPS status pill (top-left)
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isBroadcasting
                  ? const Color(0xFF166534)
                  : const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isBroadcasting)
                  FadeTransition(
                    opacity: _pulseAnimation,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                else
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
                  isBroadcasting ? 'GPS LIVE' : 'GPS OFF',
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
      ],
    );
  }

  Widget _mapControl(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }

  Widget _buildBroadcastButton(
      GpsBroadcastProvider gps, bool isBroadcasting) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () => _toggleBroadcast(gps),
          icon: Icon(
            isBroadcasting ? Icons.stop_circle : Icons.gps_fixed,
            color: Colors.white,
          ),
          label: Text(
            isBroadcasting
                ? 'Stop Live Location Sharing'
                : 'Start Live Location Sharing',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isBroadcasting
                ? const Color(0xFFDC2626) // Red when live
                : AppColors.primaryOrange, // Orange when idle
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
