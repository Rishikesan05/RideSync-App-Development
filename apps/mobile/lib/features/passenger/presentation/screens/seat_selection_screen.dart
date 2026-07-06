import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/booking_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/seat_layout_engine.dart';
import 'package:ridesync/features/passenger/presentation/screens/payment_screen.dart';

class SeatSelectionScreen extends StatelessWidget {
  final String scheduleId;
  final String layoutType;

  const SeatSelectionScreen({
    super.key, 
    required this.scheduleId, 
    required this.layoutType
  });

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: const Text('Select Your Seats', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: booking.streamSeats(scheduleId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final liveSeats = snapshot.data ?? [];
          final blueprint = SeatLayoutEngine.generateLayout(layoutType);
          
          return Column(
            children: [
              if (booking.currentRouteStops.isNotEmpty)
                _buildLocationSelectors(booking, isDark),
              if (!booking.currentRouteStops.isNotEmpty || (booking.selectedBoardingPoint != null && booking.selectedDropoffPoint != null)) ...[
                _buildLegend(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: _buildBusGrid(blueprint, liveSeats, booking, isDark),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Please select boarding and drop-off points to view seats.',
                        style: TextStyle(color: isDark ? Colors.white70 : AppColors.textDark, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
              _buildFooter(booking, auth, context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem('Available', Colors.white, border: Colors.grey.shade300),
          const SizedBox(width: 20),
          _legendItem('Selected', AppColors.primaryOrange),
          const SizedBox(width: 20),
          _legendItem('Sold', Colors.green),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, {Color? border}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: border != null ? Border.all(color: border) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
      ],
    );
  }

  Widget _buildBusGrid(List<BusSeatBlueprint> blueprint, List<Map<String, dynamic>> liveSeats, BookingProvider provider, bool isDark) {
    int cols = layoutType == '54' ? 6 : 5;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(60),
          topRight: Radius.circular(60),
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.1),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Driver Section
          _buildDriverSection(cols, isDark),
          const SizedBox(height: 24),
          // Seats
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: blueprint.length,
            itemBuilder: (context, index) {
              final bp = blueprint[index];
              if (bp.isAisle) return const SizedBox.shrink();
              if (bp.isSpacer) return const SizedBox.shrink();

              // Find live data
              final liveData = liveSeats.firstWhere(
                (s) => s['seatNumber'].toString() == bp.seatNumber,
                orElse: () => {},
              );

              bool isFullySold = false;
              double partialRatio = 0.0;
              bool hasOverlap = false;

              if (liveData.isNotEmpty && ['occupied', 'sold', 'blocked', 'reserved'].contains(liveData['status'])) {
                  final stops = provider.currentRouteStops.map((s) => s.toLowerCase()).toList();
                  
                  String normalize(String val) => val.split(',')[0].trim().toLowerCase();
                  
                  int findStopIndex(String? stopName) {
                      if (stopName == null || stopName.isEmpty) return -1;
                      final normalized = normalize(stopName);
                      int idx = stops.indexOf(normalized);
                      if (idx != -1) return idx;
                      for (int i = 0; i < stops.length; i++) {
                          if (stops[i].contains(normalized) || normalized.contains(stops[i])) {
                              return i;
                          }
                      }
                      return -1;
                  }

                  final userOrigin = provider.selectedBoardingPoint ?? provider.origin?.name ?? '';
                  final userDest = provider.selectedDropoffPoint ?? provider.destination?.name ?? '';
                  int uOIdx = findStopIndex(userOrigin);
                  int uDIdx = findStopIndex(userDest);
                  
                  if (uOIdx != -1 && uDIdx != -1 && uOIdx > uDIdx) {
                      final temp = uOIdx;
                      uOIdx = uDIdx;
                      uDIdx = temp;
                  }

                  List<dynamic> segments = liveData['segments'] ?? [];
                  if (segments.isEmpty) {
                      final o = liveData['origin'];
                      final d = liveData['destination'];
                      if (o != null && d != null && o.toString().isNotEmpty && d.toString().isNotEmpty) {
                          segments.add({'origin': o, 'destination': d});
                      }
                  }

                  if (segments.isNotEmpty && stops.length > 1) {
                      int totalSegments = stops.length - 1;
                      int coveredSegments = 0;
                      List<bool> covered = List.filled(totalSegments, false);

                      for (var seg in segments) {
                          int oIdx = findStopIndex(seg['origin']);
                          int dIdx = findStopIndex(seg['destination']);
                          
                          if (oIdx != -1 && dIdx != -1) {
                              if (oIdx > dIdx) {
                                  final temp = oIdx;
                                  oIdx = dIdx;
                                  dIdx = temp;
                              }
                              for (int i = oIdx; i < dIdx; i++) {
                                  covered[i] = true;
                              }
                              
                              if (uOIdx != -1 && uDIdx != -1) {
                                  if (uOIdx < dIdx && uDIdx > oIdx) {
                                      hasOverlap = true;
                                  }
                              } else {
                                  hasOverlap = true;
                              }
                          } else {
                              isFullySold = true;
                              hasOverlap = true;
                          }
                      }
                      
                      coveredSegments = covered.where((c) => c).length;
                      partialRatio = coveredSegments / totalSegments;
                      if (partialRatio >= 1.0) {
                          isFullySold = true;
                      }
                  } else {
                      isFullySold = true;
                      hasOverlap = true;
                  }
              }

              bool isSelected = provider.selectedSeatNumbers.contains(bp.seatNumber);

              return _SeatWidget(
                number: bp.seatNumber,
                isBooked: hasOverlap || isFullySold,
                isFullySold: isFullySold,
                partialRatio: partialRatio,
                isSelected: isSelected,
                onTap: () => provider.toggleSeat(bp.seatNumber),
                isDark: isDark,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDriverSection(int cols, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Entry Door Indicator
        Container(
          width: 28,
          height: 50,
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3), width: 2),
          ),
          child: const Center(
            child: Icon(Icons.meeting_room_outlined, size: 18, color: AppColors.primaryOrange),
          ),
        ),
        // Driver Steering Wheel
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
          child: Icon(Icons.sports_motorsports, color: isDark ? Colors.white30 : Colors.grey.shade500, size: 24),
        ),
      ],
    );
  }

  Widget _buildLocationSelectors(BookingProvider booking, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Boarding Point',
                    labelStyle: const TextStyle(fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  isExpanded: true,
                  initialValue: booking.selectedBoardingPoint != null && booking.currentRouteStops.contains(booking.selectedBoardingPoint)
                      ? booking.selectedBoardingPoint
                      : null,
                  items: booking.currentRouteStops.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    booking.setBoardingPoint(newValue);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Drop-off Point',
                    labelStyle: const TextStyle(fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  isExpanded: true,
                  initialValue: booking.selectedDropoffPoint != null && booking.currentRouteStops.contains(booking.selectedDropoffPoint)
                      ? booking.selectedDropoffPoint
                      : null,
                  items: booking.currentRouteStops.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    booking.setDropoffPoint(newValue);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BookingProvider booking, AuthProvider auth, BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${booking.selectedSeatNumbers.length} Seats Selected',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                    ),
                    Text(
                      'LKR ${booking.totalFare.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                  ElevatedButton(
                    onPressed: booking.selectedSeatNumbers.isEmpty ? null : () {
                      if (booking.currentRouteStops.isNotEmpty) {
                        if (booking.selectedBoardingPoint == null || booking.selectedDropoffPoint == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select both boarding and drop-off points'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                      }
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: booking.selectedSeatNumbers.isEmpty ? Colors.grey : AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Proceed to Pay', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatWidget extends StatelessWidget {
  final String number;
  final bool isBooked;
  final bool isFullySold;
  final double partialRatio;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _SeatWidget({
    required this.number,
    required this.isBooked,
    this.isFullySold = false,
    this.partialRatio = 0.0,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color baseBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    Color fullBgColor = isSelected 
        ? AppColors.primaryOrange 
        : (isFullySold ? Colors.green : baseBgColor);
        
    Color textColor = isSelected 
        ? Colors.white 
        : (isFullySold ? Colors.white : (isDark ? Colors.white70 : AppColors.textDark));

    Decoration decoration;
    
    if (isSelected || isFullySold || partialRatio <= 0.0) {
        decoration = BoxDecoration(
          color: fullBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryOrange 
                : (isFullySold ? Colors.transparent : (isDark ? Colors.white10 : Colors.grey.shade200)),
          ),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primaryOrange.withValues(alpha: 0.3), blurRadius: 8)] : null,
        );
    } else {
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
             color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: [partialRatio, partialRatio],
            colors: [
              Colors.green,
              baseBgColor,
            ],
          ),
        );
        // Ensure text is white if the ratio is very high and it's over the green part
        if (partialRatio > 0.5 && !isDark) textColor = Colors.white;
    }

    return GestureDetector(
      onTap: isBooked ? null : onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: decoration,
        child: Text(
          number,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
