import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/booking_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/seat_layout_engine.dart';

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
              _buildLegend(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: _buildBusGrid(blueprint, liveSeats, booking, isDark),
                ),
              ),
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
          _legendItem('Sold', Colors.grey.shade400),
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
    
    return Column(
      children: [
        // Driver Section
        _buildDriverSection(cols, isDark),
        const SizedBox(height: 20),
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

            bool isBooked = ['occupied', 'sold', 'blocked', 'reserved'].contains(liveData['status']);
            bool isSelected = provider.selectedSeatNumbers.contains(bp.seatNumber);

            return _SeatWidget(
              number: bp.seatNumber,
              isBooked: isBooked,
              isSelected: isSelected,
              onTap: () => provider.toggleSeat(bp.seatNumber),
              isDark: isDark,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDriverSection(int cols, bool isDark) {
    return Row(
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
    );
  }

  Widget _buildFooter(BookingProvider booking, AuthProvider auth, BuildContext context) {
    if (booking.selectedSeatNumbers.isEmpty) return const SizedBox.shrink();

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
                      'LKR ${booking.selectedSeatNumbers.length * 1250}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: booking.isBooking ? null : () async {
                    final success = await booking.bookSeats(auth.user?.id ?? 'guest_uid');
                    if (!context.mounted) return;
                    if (success) {
                      _showSuccessDialog(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(booking.errorMessage ?? 'Booking failed')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: booking.isBooking 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Booking Confirmed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Your seats have been reserved successfully.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to schedules
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Great!', style: TextStyle(color: Colors.white)),
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
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _SeatWidget({
    required this.number,
    required this.isBooked,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = isSelected 
        ? AppColors.primaryOrange 
        : (isBooked ? (isDark ? Colors.white10 : Colors.grey.shade300) : (isDark ? const Color(0xFF1E293B) : Colors.white));
    
    Color textColor = isSelected 
        ? Colors.white 
        : (isBooked ? AppColors.textLight : (isDark ? Colors.white70 : AppColors.textDark));

    return GestureDetector(
      onTap: isBooked ? null : onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryOrange 
                : (isBooked ? Colors.transparent : (isDark ? Colors.white10 : Colors.grey.shade200)),
          ),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primaryOrange.withValues(alpha: 0.3), blurRadius: 8)] : null,
        ),
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
