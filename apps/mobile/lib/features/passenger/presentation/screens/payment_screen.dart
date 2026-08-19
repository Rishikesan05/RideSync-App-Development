import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/confirm_exit_dialog.dart';
import 'package:ridesync/features/passenger/presentation/providers/booking_provider.dart';
import 'package:ridesync/features/passenger/presentation/screens/card_payment_screen.dart';
import 'package:ridesync/features/passenger/presentation/screens/express_payment_screen.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  Future<void> _handlePop(BuildContext context, bool didPop, dynamic result) async {
    if (didPop) return;

    final shouldLeave = await showConfirmExitDialog(
      context,
      title: 'Leave Checkout?',
      message: 'Are you sure you want to go back to seat selection?',
      confirmLabel: 'Go Back',
      cancelLabel: 'Stay Here',
      isDestructive: false,
      icon: Icons.shopping_cart_checkout_rounded,
    );

    if (shouldLeave && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handlePop(context, didPop, result),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : AppColors.textDark, size: 20),
            onPressed: () => _handlePop(context, false, null),
          ),
          title: Text(
            'Payment Methods',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 80.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceMutedDark : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.strokeDark : AppColors.stroke),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Trip Fare', style: TextStyle(color: AppColors.textLight)),
                      Text('LKR ${booking.totalFare.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Balance (Pay on Bus)', style: TextStyle(color: AppColors.textLight)),
                      Text('LKR ${booking.balanceDue.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Colors.white24),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Paying Now (Reservation)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                      Text('LKR ${booking.totalReservationFee.toStringAsFixed(0)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.success)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Select a Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _PaymentMethodCard(
              title: 'Visa or Mastercard',
              icon: Icons.credit_card,
              iconColor: AppColors.primaryNavy,
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CardPaymentScreen()),
              ),
            ),

            _PaymentMethodCard(
              title: 'Google Pay',
              icon: Icons.g_mobiledata,
              iconSize: 42,
              iconColor: Colors.green,
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpressPaymentScreen(methodName: 'Google Pay')),
              ),
            ),

            _PaymentMethodCard(
              title: 'Apple Pay',
              icon: Icons.apple,
              iconColor: isDark ? Colors.white : Colors.black,
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpressPaymentScreen(methodName: 'Apple Pay')),
              ),
            ),
            
            _PaymentMethodCard(
              title: 'PayPal',
              icon: Icons.account_balance_wallet,
              iconColor: Colors.blue.shade700,
              isDark: isDark,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PayPal integration coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final bool isDark;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.title,
    required this.icon,
    this.iconSize = 28,
    required this.iconColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.strokeDark : AppColors.stroke),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(icon, color: iconColor, size: iconSize),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}
