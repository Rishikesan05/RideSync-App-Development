import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/passenger/presentation/providers/booking_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/seat_layout_engine.dart';
import 'dart:ui';
import 'dart:math' as math;

class OperatorManageScheduleScreen extends StatelessWidget {
  final Map<String, dynamic> routeData;

  const OperatorManageScheduleScreen({
    super.key,
    required this.routeData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    // Use route id as schedule ID, or fallback
    final scheduleId = routeData['id'] ?? 'dummy_schedule_id';
    
    // Default capacity to 54 if not provided
    final capacity = (routeData['capacity'] ?? 54).toString();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: Text(routeData['id'] ?? 'Manage Schedule', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: bookingProvider.streamSeats(scheduleId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
          }

          List<Map<String, dynamic>> liveSeats = snapshot.data ?? [];
          final blueprint = SeatLayoutEngine.generateLayout(capacity);

          // Generate dummy bookings if none exist for demonstration purposes
          if (liveSeats.isEmpty) {
            liveSeats = _generateDummyBookings(blueprint);
          }

          int bookedCount = liveSeats.where((s) => s['status'] == 'sold' || s['status'] == 'occupied' || s['status'] == 'boarded').length;
          int boardedCount = liveSeats.where((s) => s['status'] == 'boarded').length;
          int totalSeats = int.tryParse(capacity) ?? 54;
          int availableCount = totalSeats - bookedCount;

          return Column(
            children: [
              _buildHeader(routeData, totalSeats, bookedCount, availableCount, boardedCount, isDark),
              _buildLegend(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: _buildBusGrid(context, blueprint, liveSeats, capacity, isDark),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _generateDummyBookings(List<BusSeatBlueprint> blueprint) {
    final random = math.Random(routeData['id'].hashCode);
    List<Map<String, dynamic>> dummies = [];
    for (var bp in blueprint) {
      if (!bp.isAisle && !bp.isSpacer) {
        // Randomly assign some seats as booked or boarded
        if (random.nextDouble() > 0.7) {
          bool isBoarded = random.nextDouble() > 0.5;
          dummies.add({
            'seatNumber': bp.seatNumber,
            'status': isBoarded ? 'boarded' : 'sold',
            'passengerId': 'USR-${random.nextInt(9000) + 1000}',
            'passengerName': 'Passenger ${random.nextInt(100)}',
            'pickup': 'Stop ${random.nextInt(5) + 1}',
            'dropoff': 'Stop ${random.nextInt(5) + 6}',
          });
        }
      }
    }
    return dummies;
  }

  Widget _buildHeader(Map<String, dynamic> route, int total, int booked, int available, int boarded, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            route['name'] ?? 'Route Name',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statBox('Total', total.toString(), Colors.white.withValues(alpha: 0.2)),
              _statBox('Booked', booked.toString(), Colors.orange.shade800),
              _statBox('Boarded', boarded.toString(), Colors.green.shade600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem('Available', Colors.white, border: Colors.grey.shade300),
          const SizedBox(width: 16),
          _legendItem('Booked', Colors.grey.shade400),
          const SizedBox(width: 16),
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: Colors.green.shade400, borderRadius: BorderRadius.circular(3)),
                child: const Icon(Icons.check, size: 10, color: Colors.white),
              ),
              const SizedBox(width: 6),
              const Text('Boarded', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600)),
            ],
          ),
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
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildBusGrid(BuildContext context, List<BusSeatBlueprint> blueprint, List<Map<String, dynamic>> liveSeats, String capacity, bool isDark) {
    int cols = capacity == '54' ? 6 : 5;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
              ),
              child: Icon(Icons.radio_button_checked, color: isDark ? Colors.white30 : Colors.grey.shade400),
            ),
            const SizedBox(width: 10),
          ],
        ),
        const SizedBox(height: 20),
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

            final liveData = liveSeats.firstWhere(
              (s) => s['seatNumber'].toString() == bp.seatNumber,
              orElse: () => {},
            );

            bool isBooked = ['occupied', 'sold'].contains(liveData['status']);
            bool isReserved = ['blocked', 'reserved'].contains(liveData['status']);
            bool isBoarded = liveData['status'] == 'boarded';

            return _OperatorSeatWidget(
              number: bp.seatNumber,
              isBooked: isBooked,
              isReserved: isReserved,
              isBoarded: isBoarded,
              isDark: isDark,
              onTap: () {
                if (isBooked || isReserved || isBoarded) {
                  _showBookingDetails(context, bp.seatNumber, liveData, isDark);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Seat ${bp.seatNumber} is currently available.')),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }

  void _showBookingDetails(BuildContext context, String seatNumber, Map<String, dynamic> bookingData, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
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
                Text('Seat $seatNumber Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bookingData['status'] == 'boarded' 
                        ? Colors.green.withValues(alpha: 0.2)
                        : (bookingData['status'] == 'reserved' ? AppColors.primaryOrange.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (bookingData['status'] ?? 'Unknown').toString().toUpperCase(),
                    style: TextStyle(
                      color: bookingData['status'] == 'boarded' 
                          ? Colors.green
                          : (bookingData['status'] == 'reserved' ? AppColors.primaryOrange : Colors.blue),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _detailRow(Icons.person, 'Passenger', bookingData['passengerName'] ?? bookingData['passengerId'] ?? 'Unknown', isDark),
            const SizedBox(height: 16),
            _detailRow(Icons.trip_origin, 'Boarding', bookingData['pickup'] ?? 'Pettah Terminal', isDark),
            const SizedBox(height: 16),
            _detailRow(Icons.location_on, 'Drop-off', bookingData['dropoff'] ?? 'Kaduwela', isDark),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 12)),
            Text(value, style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _OperatorSeatWidget extends StatelessWidget {
  final String number;
  final bool isBooked;
  final bool isReserved;
  final bool isBoarded;
  final bool isDark;
  final VoidCallback onTap;

  const _OperatorSeatWidget({
    required this.number,
    required this.isBooked,
    required this.isReserved,
    required this.isBoarded,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    if (isBoarded) {
      bgColor = Colors.green.shade400;
      textColor = Colors.white;
    } else if (isBooked) {
      bgColor = isDark ? Colors.white10 : Colors.grey.shade300;
      textColor = AppColors.textLight;
    } else if (isReserved) {
      bgColor = AppColors.primaryOrange;
      textColor = Colors.white;
    } else {
      bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
      textColor = isDark ? Colors.white70 : AppColors.textDark;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isReserved 
                ? AppColors.primaryOrange 
                : ((isBooked || isBoarded) ? Colors.transparent : (isDark ? Colors.white10 : Colors.grey.shade200)),
          ),
          boxShadow: isReserved ? [BoxShadow(color: AppColors.primaryOrange.withValues(alpha: 0.3), blurRadius: 8)] : null,
        ),
        child: isBoarded
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                number,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: (isBooked || isReserved) ? FontWeight.bold : FontWeight.w500,
                  color: textColor,
                ),
              ),
      ),
    );
  }
}
