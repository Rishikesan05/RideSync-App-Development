import 'package:flutter/material.dart';
import 'package:ridesync/core/constants.dart';

/// Booking Confirmed "Boarding Pass" screen matching the Figma design.
/// Shows route, seat, boarding hub, destination, and fare breakdown.
class BookingConfirmationScreen extends StatelessWidget {
  final String routeName;
  final String seatNumbers;
  final String origin;
  final String destination;
  /// Full route face value (e.g. Jaffna → Colombo = LKR 1 200).
  /// This is what the passenger sees on their ticket.
  final double endPrice;
  /// Price for the passenger's actual boarding→drop-off leg.
  /// Shown in the fare breakdown for transparency.
  final double stopPrice;
  final double totalFare;
  final int seatCount;
  final String plateNumber;
  final String ticketCode;
  final double reservationPaid;
  final double balanceDue;

  const BookingConfirmationScreen({
    super.key,
    required this.routeName,
    required this.seatNumbers,
    required this.origin,
    required this.destination,
    required this.endPrice,
    required this.stopPrice,
    required this.totalFare,
    required this.seatCount,
    required this.plateNumber,
    required this.ticketCode,
    required this.reservationPaid,
    required this.balanceDue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F8F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Success icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.green, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Booking Successful!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'SEAT ${seatNumbers.toUpperCase()} RESERVED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 32),

              // Boarding Pass card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Bus icon + boarding pass label
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.directions_bus, color: AppColors.primaryOrange, size: 28),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'RIDESYNC BOARDING PASS',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),

                    // Divider with circles (ticket-style cutout look)
                    Row(
                      children: [
                        CircleAvatar(radius: 12, backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F8F8)),
                        Expanded(
                          child: LayoutBuilder(builder: (context, constraints) {
                            return Row(
                              children: List.generate(
                                (constraints.maxWidth / 8).floor(),
                                (index) => Container(
                                  width: 4,
                                  height: 1,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  color: isDark ? Colors.white10 : Colors.grey.shade300,
                                ),
                              ),
                            );
                          }),
                        ),
                        CircleAvatar(radius: 12, backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F8F8)),
                      ],
                    ),

                    // Route & Seat
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ROUTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textLight, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Text(
                                routeName.isNotEmpty ? '#${routeName.substring(0, routeName.length > 6 ? 6 : routeName.length)}' : '#RS',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('SEATING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textLight, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Text(
                                seatNumbers,
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primaryOrange),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Boarding Hub → Destination
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('BOARDING HUB', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textLight, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Text(origin, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primaryOrange, shape: BoxShape.circle)),
                                  Expanded(child: Container(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade300)),
                                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.textLight),
                                  Expanded(child: Container(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade300)),
                                  Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.primaryOrange, shape: BoxShape.circle, border: Border.all(color: AppColors.primaryOrange, width: 2))),
                                ],
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('DESTINATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textLight, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Text(destination, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Barcode placeholder
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(25, (i) {
                          final widths = [3.0, 1.0, 2.0, 1.0, 3.0, 2.0, 1.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 1.0, 3.0, 2.0, 1.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 1.0, 3.0];
                          return Container(
                            width: widths[i],
                            height: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            color: isDark ? Colors.white30 : Colors.black54,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ticketCode,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 4),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Ride Summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RIDE SUMMARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textLight, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    const Text('Ticket Face Value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(
                      'Rs. ${(endPrice * seatCount).toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryOrange),
                    ),

                    const SizedBox(height: 16),

                    // Route-stop fare info box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.route, size: 18, color: AppColors.primaryOrange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Route-Stop Pricing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                Text(
                                  'Your leg fare: LKR ${stopPrice.toStringAsFixed(0)} × $seatCount seat${seatCount > 1 ? 's' : ''}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Fare breakdown
                    _fareRow('Your Leg Fare', 'Rs. ${stopPrice.toStringAsFixed(0)}'),
                    _fareRow('Full Ticket Price', 'Rs. ${endPrice.toStringAsFixed(0)}'),
                    if (seatCount > 1) _fareRow('Seats', '× $seatCount'),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Trip Fare', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                        Text(
                          'Rs. ${totalFare.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Reservation Deposit Paid', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                        Text(
                          'Rs. ${reservationPaid.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.success),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Balance Due on Bus', style: TextStyle(fontSize: 14, color: AppColors.primaryOrange, fontWeight: FontWeight.w800)),
                          Text(
                            'Rs. ${balanceDue.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryOrange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Launch Live Map button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    // The user can tap Live tab from bottom nav
                  },
                  icon: const Icon(Icons.near_me, size: 18),
                  label: const Text('LAUNCH LIVE MAP', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Done button
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fareRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
