import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/custom_button.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/booking_provider.dart';
import 'package:ridesync/features/passenger/presentation/screens/booking_confirmation_screen.dart';

class ExpressPaymentScreen extends StatefulWidget {
  final String methodName;

  const ExpressPaymentScreen({super.key, required this.methodName});

  @override
  State<ExpressPaymentScreen> createState() => _ExpressPaymentScreenState();
}

class _ExpressPaymentScreenState extends State<ExpressPaymentScreen> {
  bool _isProcessing = false;

  void _processPayment(BuildContext context, BookingProvider booking, AuthProvider auth) async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing / face ID auth time
    await Future.delayed(const Duration(seconds: 2));

    // After simulated success, book seats on backend
    final success = await booking.bookSeats(auth.user?.id ?? 'guest_uid');
    
    if (!context.mounted) return;

    setState(() {
      _isProcessing = false;
    });

    if (success) {
      _showSuccessDialog(context, booking);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(booking.errorMessage ?? 'Booking failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessDialog(BuildContext context, BookingProvider booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your ${widget.methodName} reservation payment of LKR ${booking.totalReservationFee.toStringAsFixed(0)} was successful. Your appointment has been booked.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight, height: 1.5),
            ),
            const SizedBox(height: 32),
            CustomButton(
              label: 'View Ticket',
              color: AppColors.primaryOrange,
              onPressed: () {
                Navigator.pop(ctx); // close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingConfirmationScreen(
                      routeName: booking.selectedSchedule?.routeName ?? 'Express',
                      seatNumbers: booking.selectedSeatNumbers.join(', '),
                      origin: booking.origin?.name ?? '',
                      destination: booking.destination?.name ?? '',
                      farePerSeat: booking.farePerSeat,
                      totalFare: booking.totalFare,
                      distanceKm: booking.distanceKm,
                      seatCount: booking.selectedSeatNumbers.length,
                      plateNumber: booking.selectedSchedule?.plateNumber ?? 'Unknown',
                      ticketCode: booking.lastGeneratedTicketCode ?? 'TICKET',
                      reservationPaid: booking.totalReservationFee,
                      balanceDue: booking.balanceDue,
                    ),
                  ),
                  (route) => route.isFirst,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final isApple = widget.methodName == 'Apple Pay';

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32.0, 32.0, 32.0, 80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isApple ? Icons.apple : Icons.g_mobiledata, 
                    size: isApple ? 50 : 60, 
                    color: Colors.white
                  ),
                  if (isApple)
                    const Text('Pay', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))
                  else
                    const Text('Pay', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 64),
              
              // Amount Box
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    Text(
                      'RESERVATION DEPOSIT', 
                      style: TextStyle(
                        fontSize: 14, 
                        color: isDark ? Colors.white70 : Colors.black54, 
                        letterSpacing: 1.5, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'LKR ${booking.totalReservationFee.toStringAsFixed(0)}', 
                      style: TextStyle(
                        fontSize: 40, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : AppColors.textDark
                      )
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 64),
              
              // Mock selected card
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.credit_card, size: 16, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  const Text('Mastercard •••• 5678', style: TextStyle(fontSize: 18, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 64),

              // Double click to pay / Auth simulation
              if (_isProcessing)
                const CircularProgressIndicator(color: Colors.white)
              else
                Column(
                  children: [
                    const Icon(Icons.fingerprint, size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text('Confirm with Touch ID / Face ID', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _processPayment(context, booking, auth),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text('Simulate Auth', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
