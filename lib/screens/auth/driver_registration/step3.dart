import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../../core/constants.dart';
import '../../../widgets/custom_button.dart';

// Step 3: Review & Final Authorization with Digital Signature
class Step3 extends StatefulWidget {
  final VoidCallback onBack;

  const Step3({super.key, required this.onBack});

  @override
  State<Step3> createState() => _Step3State();
}

class _Step3State extends State<Step3> {
  final SignatureController _controller = SignatureController(
    onDrawStart: () => debugPrint('onDrawStart called!'),
    onDrawEnd: () => debugPrint('onDrawEnd called!'),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Final Review',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Check your details before submission. By signing below, you authorize RideSync to verify your professional documents.',
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Digital Signature',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Signature(
                controller: _controller,
                height: 200,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _controller.clear(),
                child: Text(
                  'Clear Signature',
                  style: TextStyle(
                    color: isDark ? AppColors.primaryOrange : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          CustomButton(
            label: 'Submit Registration',
            onPressed: () {
              _showSuccessDialog();
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onBack,
            child: Center(
              child: Text(
                'Review Previous Steps',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registration Pending'),
        content: const Text(
          'Your form is pending verification. Our team will review your professional documents shortly.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/main',
                (route) => false,
                arguments: {'index': 0},
              );
            },
            child: const Text('OK, GO HOME'),
          ),
        ],
      ),
    );
  }
}
