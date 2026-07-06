import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/passenger/presentation/providers/booking_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/finder_provider.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/features/passenger/presentation/screens/seat_selection_screen.dart';
import 'package:ridesync/features/passenger/data/models/route_models.dart';

class BookingScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const BookingScreen({super.key, this.onBack});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  final FocusNode _originFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers if provider already has data (e.g. from Finder)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final booking = Provider.of<BookingProvider>(context, listen: false);
      if (booking.origin != null) _originController.text = booking.origin!.name;
      if (booking.destination != null) _destController.text = booking.destination!.name;
    });

    _originController.addListener(() {
      if (_originFocus.hasFocus && _originController.text.isNotEmpty) {
        context.read<FinderProvider>().fetchSuggestions(_originController.text, 'origin');
      }
    });
    _destController.addListener(() {
      if (_destFocus.hasFocus && _destController.text.isNotEmpty) {
        context.read<FinderProvider>().fetchSuggestions(_destController.text, 'destination');
      }
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _originFocus.dispose();
    _destFocus.dispose();
    super.dispose();
  }

  void _handleSuggestionTap(Place place) async {
    final finder = context.read<FinderProvider>();
    final booking = context.read<BookingProvider>();

    if (_originFocus.hasFocus) {
      await finder.selectOrigin(place);
      _originController.text = finder.origin!.name;
      booking.setOrigin(finder.origin!);
      _originFocus.unfocus();
    } else if (_destFocus.hasFocus) {
      await finder.selectDestination(place);
      _destController.text = finder.destination!.name;
      booking.setDestination(finder.destination!);
      _destFocus.unfocus();
    }
    finder.fetchSuggestions('', ''); // Clear suggestions
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
        title: const Text('Book Your Ride', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        leading: widget.onBack != null 
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)
          : null,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildSearchHeader(booking, isDark),
            ),
          ),
          _buildSchedulesSliver(booking, isDark),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(BookingProvider booking, bool isDark) {
    final finder = context.watch<FinderProvider>();
    final showOriginSuggestions = finder.suggestions.isNotEmpty && _originFocus.hasFocus;
    final showDestSuggestions = finder.suggestions.isNotEmpty && _destFocus.hasFocus;

    Widget buildSuggestions() {
      return Container(
        constraints: const BoxConstraints(maxHeight: 180),
        margin: const EdgeInsets.only(top: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: finder.suggestions.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
          itemBuilder: (context, index) {
            final place = finder.suggestions[index];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.place_outlined, color: AppColors.primaryOrange, size: 20),
              title: Text(place.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppColors.textDark)),
              subtitle: Text(place.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
              onTap: () => _handleSuggestionTap(place),
            );
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          _LocationField(
            label: 'FROM',
            hint: 'your current location',
            icon: Icons.gps_fixed_rounded,
            iconColor: AppColors.accentBlue,
            isDark: isDark,
            controller: _originController,
            focusNode: _originFocus,
          ),
          if (showOriginSuggestions) buildSuggestions(),
          const SizedBox(height: 14),
          _LocationField(
            label: 'TO',
            hint: 'Where to go today?',
            icon: Icons.location_on_outlined,
            iconColor: AppColors.primaryOrange,
            isDark: isDark,
            controller: _destController,
            focusNode: _destFocus,
          ),
          if (showDestSuggestions) buildSuggestions(),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildDateChip('Today', DateTime.now(), booking, isDark),
              const SizedBox(width: 8),
              _buildDateChip('Tomorrow', DateTime.now().add(const Duration(days: 1)), booking, isDark),
            ],
          ),
          const SizedBox(height: 14),
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

  Widget _buildDateChip(String label, DateTime date, BookingProvider booking, bool isDark) {
    final isSelected = booking.selectedDate.year == date.year &&
                       booking.selectedDate.month == date.month &&
                       booking.selectedDate.day == date.day;

    return GestureDetector(
      onTap: () => booking.setDate(date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : (isDark ? Colors.white10 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : (isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.05)),
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: AppColors.primaryOrange.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textDark),
          ),
        ),
      ),
    );
  }

  Widget _buildSchedulesSliver(BookingProvider booking, bool isDark) {
    if (booking.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
      );
    }

    if (booking.errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
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
        ),
      );
    }

    if (booking.availableSchedules.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('Enter details to find available buses', style: TextStyle(color: AppColors.textLight)),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final schedule = booking.availableSchedules[index];
            return _buildScheduleCard(schedule, booking, isDark);
          },
          childCount: booking.availableSchedules.length,
        ),
      ),
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
                  booking.formattedFarePerSeat,
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
          if (booking.endPrice > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.route, size: 16, color: AppColors.textLight),
                  const SizedBox(width: 8),
                  Text(
                    'Ticket: LKR ${booking.endPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                  const SizedBox(width: 12),
                  if (booking.stopPrice > 0)
                    ...[
                      const Icon(Icons.pin_drop_outlined, size: 16, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(
                        'Leg: LKR ${booking.stopPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                      ),
                    ],
                ],
              ),
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

}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.controller,
    required this.focusNode,
  });

  final String label;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      color: isDark ? Colors.white38 : AppColors.textLight,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
