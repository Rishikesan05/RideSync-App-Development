import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/passenger/presentation/providers/booking_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/finder_provider.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/features/passenger/presentation/screens/seat_selection_screen.dart';

class BookingScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const BookingScreen({super.key, this.onBack});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers if provider already has data (e.g. from Finder)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final booking = Provider.of<BookingProvider>(context, listen: false);
      if (booking.origin != null) _originController.text = booking.origin!.name;
      if (booking.destination != null) _destController.text = booking.destination!.name;
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, BookingProvider booking) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: booking.selectedDate.isBefore(firstDate) ? firstDate : booking.selectedDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryOrange,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != booking.selectedDate) {
      booking.setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: const Text('Book Your Ride', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onBack != null 
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)
          : null,
      ),
      body: Column(
        children: [
          _buildSearchHeader(booking, isDark),
          Expanded(
            child: _buildSchedulesList(booking, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(BookingProvider booking, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _buildLocationInput(
            hint: 'From',
            icon: Icons.circle_outlined,
            controller: _originController,
            onTap: () => _showPlaceSearch(true, booking),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildLocationInput(
            hint: 'To',
            icon: Icons.location_on_outlined,
            controller: _destController,
            onTap: () => _showPlaceSearch(false, booking),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, booking),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.primaryOrange),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEE, MMM d').format(booking.selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: booking.isLoading ? null : () => booking.searchSchedules(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: booking.isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInput({
    required String hint, 
    required IconData icon, 
    required TextEditingController controller, 
    required VoidCallback onTap,
    required bool isDark
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textLight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.text.isEmpty ? hint : controller.text,
                style: TextStyle(
                  color: controller.text.isEmpty ? AppColors.textLight : (isDark ? Colors.white : AppColors.textDark),
                  fontWeight: controller.text.isEmpty ? FontWeight.normal : FontWeight.w600
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulesList(BookingProvider booking, bool isDark) {
    if (booking.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
    }

    if (booking.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(booking.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textLight)),
            ],
          ),
        ),
      );
    }

    if (booking.availableSchedules.isEmpty) {
      return const Center(
        child: Text('Enter details to find available buses', style: TextStyle(color: AppColors.textLight)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: booking.availableSchedules.length,
      itemBuilder: (context, index) {
        final schedule = booking.availableSchedules[index];
        return _buildScheduleCard(schedule, booking, isDark);
      },
    );
  }

  Widget _buildScheduleCard(ScheduleModel schedule, BookingProvider booking, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(schedule.departureTime),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    schedule.routeName ?? 'Express Service',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LKR 1,250', // Mock fare for now
                  style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.directions_bus, size: 16, color: AppColors.textLight),
              const SizedBox(width: 8),
              Text(schedule.plateNumber ?? 'WP-1234', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.event_seat, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Text('${schedule.capacity} Seats', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              
              if (auth.user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please login to book seats'),
                    backgroundColor: AppColors.primaryOrange,
                  ),
                );
                // Optionally redirect to login tab or show login modal
                return;
              }

              booking.selectSchedule(schedule);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeatSelectionScreen(
                    scheduleId: schedule.id,
                    layoutType: schedule.capacity.toString(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
              foregroundColor: AppColors.primaryOrange,
              elevation: 0,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.primaryOrange)
              ),
            ),
            child: const Text('Select Seats', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPlaceSearch(bool isOrigin, BookingProvider booking) {
    final finder = Provider.of<FinderProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Search City', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Type at least 3 letters...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.primaryOrange),
                          filled: true,
                          fillColor: Colors.grey.withValues(alpha: 0.1),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (value) async {
                          if (value.length >= 3) {
                            await finder.fetchSuggestions(value, isOrigin ? 'origin' : 'destination');
                            setModalState(() {}); // Rebuild with suggestions
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: finder.suggestions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.keyboard_outlined, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('Type 3+ letters to search', style: TextStyle(color: Colors.grey.shade400)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: finder.suggestions.length,
                          itemBuilder: (context, index) {
                            final place = finder.suggestions[index];
                            return ListTile(
                              leading: const Icon(Icons.location_city, size: 20, color: AppColors.primaryOrange),
                              title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Text(place.address, style: const TextStyle(fontSize: 12)),
                              onTap: () async {
                                // Important: We need coordinates for the booking search to work well
                                // Fetching place details through FinderProvider
                                if (isOrigin) {
                                  await finder.selectOrigin(place);
                                  _originController.text = finder.origin!.name;
                                  booking.setOrigin(finder.origin!);
                                } else {
                                  await finder.selectDestination(place);
                                  _destController.text = finder.destination!.name;
                                  booking.setDestination(finder.destination!);
                                }
                                if (context.mounted) Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}
