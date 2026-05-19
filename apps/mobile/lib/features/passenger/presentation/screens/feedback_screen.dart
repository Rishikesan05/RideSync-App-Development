import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/core/widgets/custom_button.dart';

class FeedbackScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const FeedbackScreen({super.key, required this.bookingData});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id;

    if (userId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final scheduleId = widget.bookingData['scheduleId'] ?? '';
      final busId = widget.bookingData['busId'] ?? '';
      final operatorId = widget.bookingData['operatorId'] ?? '';

      // Create feedback record
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': userId,
        'passengerId': userId, // include both to be safe
        'scheduleId': scheduleId,
        'busId': busId,
        'operatorId': operatorId,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Optionally, mark the booking as "reviewed"
      final bookingId = widget.bookingData['id'];
      if (bookingId != null && bookingId.toString().isNotEmpty) {
        await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
          'hasFeedback': true,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routeName = widget.bookingData['routeName'] ?? 
        '${widget.bookingData['origin']} → ${widget.bookingData['destination']}';
    final plateNumber = widget.bookingData['plateNumber'] ?? '';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Rate Your Trip', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // Illustration or Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bus_filled,
                size: 50,
                color: AppColors.primaryOrange,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Trip Details
            Text(
              'How was your ride?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$routeName\n$plateNumber',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 48,
                    color: index < _rating ? AppColors.primaryOrange : Colors.grey.shade400,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            
            const SizedBox(height: 12),
            Text(
              _getRatingText(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _rating > 0 ? AppColors.primaryOrange : Colors.transparent,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Comment Field
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 250,
              decoration: InputDecoration(
                hintText: 'Tell us about your experience (optional)',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: CustomButton(
                label: 'Submit Feedback',
                isLoading: _isSubmitting,
                onPressed: _rating > 0 ? () { _submitFeedback(); } : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1: return 'Terrible';
      case 2: return 'Poor';
      case 3: return 'Okay';
      case 4: return 'Good';
      case 5: return 'Excellent!';
      default: return '';
    }
  }
}
