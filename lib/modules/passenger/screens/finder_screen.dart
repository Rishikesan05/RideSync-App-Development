import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/modules/passenger/providers/finder_provider.dart';
import 'package:ridesync/modules/passenger/data/route_models.dart';

class RouteFinderScreen extends StatefulWidget {
  const RouteFinderScreen({super.key});

  @override
  State<RouteFinderScreen> createState() => _RouteFinderScreenState();
}

class _RouteFinderScreenState extends State<RouteFinderScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  final FocusNode _originFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();
  
  bool _myLocationEnabled = false;
  String? _lastErrorMessage;
  double _mapRotation = 0.0;
  
  Place? _lastOrigin;
  Place? _lastDestination;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        setState(() {
          _myLocationEnabled = true;
        });
        // Initial move to user location if already permitted
        _animateToUserLocation();
      }
    } catch (e) {
      debugPrint('Location permission error: $e');
    }
  }

  Future<void> _animateToUserLocation() async {
    try {
      // Small delay to ensure map controller is ready
      if (_mapController == null) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _originFocus.dispose();
    _destFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _syncControllers(FinderProvider finder) {
    // Sync text fields with provider state if they differ
    // This handles swaps and external updates
    if (finder.origin?.name != _originController.text && !_originFocus.hasFocus) {
      _originController.text = finder.origin?.name ?? '';
    }
    if (finder.destination?.name != _destController.text && !_destFocus.hasFocus) {
      _destController.text = finder.destination?.name ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final finder = Provider.of<FinderProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _syncControllers(finder);
    
    // Auto-fit bounds if locations changed
    if (finder.origin != _lastOrigin || finder.destination != _lastDestination) {
      _lastOrigin = finder.origin;
      _lastDestination = finder.destination;
      
      final points = <LatLng>[];
      // Only add points that have valid (non-zero) coordinates
      if (finder.origin != null && finder.origin!.position.latitude != 0) {
        points.add(finder.origin!.position);
      }
      if (finder.destination != null && finder.destination!.position.latitude != 0) {
        points.add(finder.destination!.position);
      }
      
      if (points.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitToPoints(points);
        });
      }
    }

    // Show error if it exists and is new
    if (finder.errorMessage != null && finder.errorMessage != _lastErrorMessage) {
      _lastErrorMessage = finder.errorMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(finder.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildMap(finder, isDark),
          _buildFloatingSearchHeader(context, finder, isDark),
          _buildMapControls(isDark), // New Side Controls
          if (finder.routes.isNotEmpty) _buildHorizontalResultsPanel(finder, isDark),
          if (finder.routes.isEmpty && finder.errorMessage != null && finder.errorMessage!.contains('No fare data')) 
            _buildNoResultsPanel(finder, isDark),
          if (finder.isLoading) _buildLoadingOverlay(isDark),
          if (!finder.isInitialized || !finder.isConfigValid) _buildInitializationOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildMap(FinderProvider finder, bool isDark) {
    // Calculate padding based on UI visibility
    // Header is approx 200px (with safe area), Bottom panel is 280px (increased)
    final topPadding = MediaQuery.of(context).padding.top + (finder.isInitialized ? 200.0 : 0.0);
    // Increased bottom padding to 280 to perfectly clear the taller horizontal cards
    final showPanel = finder.routes.isNotEmpty || (finder.errorMessage != null && finder.errorMessage!.contains('No fare data'));
    final bottomPadding = showPanel ? 280.0 : 40.0;

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(6.6747, 80.6401), // Sabaragamuwa region
        zoom: 12,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        if (_myLocationEnabled) _animateToUserLocation();
      },
      myLocationEnabled: _myLocationEnabled,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      mapType: MapType.normal,
      markers: _buildMarkers(finder),
      polylines: _buildPolylines(finder),
      style: isDark ? _darkMapStyle : null,
      onCameraMove: (position) {
        if (mounted) setState(() => _mapRotation = position.bearing);
      },
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
    );
  }

  Set<Marker> _buildMarkers(FinderProvider finder) {
    final Set<Marker> markers = {};
    if (finder.origin != null) {
      markers.add(Marker(
        markerId: const MarkerId('origin'),
        position: finder.origin!.position,
        infoWindow: InfoWindow(title: finder.origin!.name),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    }
    if (finder.destination != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: finder.destination!.position,
        infoWindow: InfoWindow(title: finder.destination!.name),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }
    return markers;
  }

  Set<Polyline> _buildPolylines(FinderProvider finder) {
    if (finder.routes.isEmpty) return {};
    
    return finder.routes.map((route) {
      final isSelected = finder.selectedRoute?.id == route.id;
      return Polyline(
        polylineId: PolylineId(route.id),
        points: route.polylinePoints,
        color: isSelected 
            ? AppColors.primaryOrange 
            : (Theme.of(context).brightness == Brightness.dark 
               ? Colors.white24 
               : Colors.black12),
        width: isSelected ? 6 : 3,
        zIndex: isSelected ? 10 : 1,
        onTap: () => finder.selectRoute(route),
        consumeTapEvents: true,
      );
    }).toSet();
  }

  Widget _buildFloatingSearchHeader(BuildContext context, FinderProvider finder, bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Removed individual _buildCompass(isDark) from here
            
            // Search Container
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12, width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    children: [
                      // Header Label
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.directions_bus_filled, color: AppColors.primaryOrange, size: 16),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Bus Route Finder',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      
                      // Inputs with centered swap
                      Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                _buildCompactInput(
                                  'Starting Point',
                                  Icons.circle,
                                  _originController,
                                  _originFocus,
                                  (val) => finder.fetchSuggestions(val, 'origin'),
                                  isDark,
                                  iconColor: Colors.blueAccent,
                                ),
                                const SizedBox(height: 8),
                                _buildCompactInput(
                                  'Destination',
                                  Icons.location_on,
                                  _destController,
                                  _destFocus,
                                  (val) => finder.fetchSuggestions(val, 'destination'),
                                  isDark,
                                  iconColor: AppColors.primaryOrange,
                                ),
                              ],
                            ),
                          ),
                          
                          // Centered Swap Button
                          Positioned(
                            right: 20,
                            top: 45, // Centered between the two inputs
                            child: GestureDetector(
                              onTap: () {
                                finder.swapLocations();
                                final points = <LatLng>[];
                                if (finder.origin != null) points.add(finder.origin!.position);
                                if (finder.destination != null) points.add(finder.destination!.position);
                                if (points.isNotEmpty) _fitToPoints(points);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))
                                  ],
                                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                ),
                                child: const Icon(Icons.swap_vert, size: 20, color: AppColors.primaryOrange),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (finder.suggestions.isNotEmpty)
                        _buildSuggestionsOverlay(finder, isDark),
                    ],
                  ),
                ),
              ),
            ),
            
            // Search Button
            if (finder.origin != null && finder.destination != null && finder.suggestions.isEmpty && finder.routes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Container(
                    width: 200,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryOrange, Color(0xFFFF8C42)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: AppColors.primaryOrange.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6))
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                         FocusScope.of(context).unfocus();
                         finder.searchRoutes();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 20),
                          SizedBox(width: 8),
                          Text('Find Bus Routes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls(bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Zoom Controls Panel
            Container(
              width: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    children: [
                      _buildControlItem(
                        Icons.add,
                        () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                        isDark,
                      ),
                      const Divider(height: 1, indent: 8, endIndent: 8),
                      _buildControlItem(
                        Icons.remove,
                        () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                        isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Compass / Recenter Button
            _buildCompass(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildControlItem(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(icon, size: 24, color: AppColors.primaryOrange),
      ),
    );
  }

  Widget _buildCompass(bool isDark) {
    // Show compass faded if rotation is 0
    final isHidden = _mapRotation == 0.0;
    
    return AnimatedOpacity(
      opacity: isHidden ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: () {
          _mapController?.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: _mapController?.getVisibleRegion() != null ? const LatLng(7.8731, 80.7718) : const LatLng(7.8731, 80.7718), zoom: 7, bearing: 0, tilt: 0),
          ));
          if (mounted) setState(() => _mapRotation = 0.0);
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
            ],
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Transform.rotate(
              angle: -_mapRotation * (pi / 180),
              child: const Icon(Icons.navigation, color: Colors.blueAccent, size: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInput(String hint, IconData icon, TextEditingController controller, FocusNode focus, Function(String) onChanged, bool isDark, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? (isDark ? Colors.white60 : Colors.black45), size: 14),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focus,
              onChanged: onChanged,
              onSubmitted: (_) {
                if (focus == _originFocus) {
                  _destFocus.requestFocus();
                }
              },
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                if (focus == _originFocus) {
                  Provider.of<FinderProvider>(context, listen: false).clearOrigin();
                } else {
                  Provider.of<FinderProvider>(context, listen: false).clearDestination();
                }
              },
              child: Icon(Icons.close, size: 14, color: isDark ? Colors.white38 : Colors.black38),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsOverlay(FinderProvider finder, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: finder.suggestions.length,
        separatorBuilder: (_, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
        itemBuilder: (context, index) {
          final s = finder.suggestions[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.place_outlined, size: 16, color: AppColors.textLight),
            title: Text(s.name, style: const TextStyle(fontSize: 13)),
            subtitle: Text(s.address, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () async {
              final isDest = finder.lastFocusedField == 'destination' || _destFocus.hasFocus;
              if (isDest) {
                _destController.text = s.name;
                finder.selectDestination(s);
              } else {
                _originController.text = s.name;
                finder.selectOrigin(s);
              }
              FocusScope.of(context).unfocus();
              
              // Wait a tiny bit for the provider to update if it was fetching details
              await Future.delayed(const Duration(milliseconds: 300));
              
              final points = <LatLng>[];
              // Use valid coordinates only
              if (finder.origin != null && finder.origin!.position.latitude != 0) {
                points.add(finder.origin!.position);
              }
              if (finder.destination != null && finder.destination!.position.latitude != 0) {
                points.add(finder.destination!.position);
              }
              if (points.isNotEmpty) _fitToPoints(points);
            },
          );
        },
      ),
    );
  }

  Widget _buildHorizontalResultsPanel(FinderProvider finder, bool isDark) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 280, // Increased height
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, -2))
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Available Bus Routes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${finder.routes.length} options', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: finder.routes.length,
                itemBuilder: (context, index) {
                  final route = finder.routes[index];
                  return _buildRouteCard(route, finder, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsPanel(FinderProvider finder, bool isDark) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 280, // Consistent height
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, -2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline, color: AppColors.primaryOrange, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Fare Data Available',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'We are currently expanding our coverage. Try searching for major district pairs like Colombo to Kandy or Galle.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => finder.clearSearch(),
              child: const Text('Clear Search', style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(RouteRecommendation route, FinderProvider finder, bool isDark) {
    final isSelected = finder.selectedRoute?.id == route.id;
    return GestureDetector(
      onTap: () {
        finder.selectRoute(route);
        _animateToRoute(route);
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryOrange.withValues(alpha: 0.08) 
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : (isDark ? Colors.white10 : Colors.grey.shade100),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: isSelected ? 0.1 : 0.05), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _getTypeColor(route.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(_getTypeIcon(route.type), size: 14, color: _getTypeColor(route.type)),
                    ),
                    const SizedBox(width: 8),
                    Text(route.typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getTypeColor(route.type))),
                  ],
                ),
                if (route.isRecommended)
                  const Text('⭐ BEST', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.primaryOrange)),
              ],
            ),
            const SizedBox(height: 12),
            Text(route.duration, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 4),
            Text('${route.distance} • ${route.currency} ${route.fare.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textLight)),
            if (route.hasStoredFare)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('✓ ${route.fareSource}', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            Text(
              route.reason, 
              maxLines: 3, // Increased lines
              overflow: TextOverflow.visible, // Don't clip if possible
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  void _animateToRoute(RouteRecommendation route) {
    if (route.polylinePoints.isEmpty) return;
    _fitToPoints(route.polylinePoints);
  }

  void _fitToPoints(List<LatLng> points) {
    if (points.isEmpty) return;
    
    // Single point: zoom in smoothly
    if (points.length == 1) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 15),
        ),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60, // Balanced internal padding (on top of GoogleMap.padding)
      ),
    );
  }

  Color _getTypeColor(RecommendationType type) {
    switch (type) {
      case RecommendationType.fastest: return Colors.blue;
      case RecommendationType.safest: return Colors.green;
      case RecommendationType.economic: return Colors.orange;
    }
  }

  IconData _getTypeIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.fastest: return Icons.directions_bus;
      case RecommendationType.safest: return Icons.map;
      case RecommendationType.economic: return Icons.account_balance_wallet;
    }
  }

  Widget _buildLoadingOverlay(bool isDark) {
    return Container(
      color: Colors.black45,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      ),
    );
  }

  Widget _buildInitializationOverlay(bool isDark) {
    if (Provider.of<FinderProvider>(context).errorMessage != null && !Provider.of<FinderProvider>(context).isConfigValid) {
       return _buildConfigurationErrorOverlay(isDark, Provider.of<FinderProvider>(context).errorMessage!);
    }

    return Container(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryOrange),
            const SizedBox(height: 24),
            Text(
              'Initializing API Config...',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Securely identifying application',
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationErrorOverlay(bool isDark, String error) {
    return Container(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 24),
            Text(
              'Configuration Failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Restart logic or just notify
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please check local.properties and restart the app.'))
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
              child: const Text('HOW TO FIX', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#263c3f"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#38414e"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#212a37"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#17263c"}]
  }
]
''';
}





