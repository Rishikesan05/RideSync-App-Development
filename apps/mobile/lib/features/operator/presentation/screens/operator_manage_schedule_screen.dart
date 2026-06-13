import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/passenger/presentation/providers/booking_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/seat_layout_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class OperatorManageScheduleScreen extends StatefulWidget {
  final Map<String, dynamic> routeData;

  const OperatorManageScheduleScreen({
    super.key,
    required this.routeData,
  });

  @override
  State<OperatorManageScheduleScreen> createState() => _OperatorManageScheduleScreenState();
}

class _OperatorManageScheduleScreenState extends State<OperatorManageScheduleScreen> {
  String _searchQuery = '';
  bool _isGridView = true;
  String? _selectedStopFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final scheduleId = widget.routeData['id'] ?? 'dummy_schedule_id';
    final capacity = (widget.routeData['capacity'] ?? 54).toString();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: Text(widget.routeData['id'] ?? 'Manage Schedule', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list_alt_rounded : Icons.grid_view_rounded),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: bookingProvider.streamSeats(scheduleId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
          }

          List<Map<String, dynamic>> liveSeats = snapshot.data ?? [];
          final blueprint = SeatLayoutEngine.generateLayout(capacity);

          int bookedCount = liveSeats.where((s) => s['status'] == 'sold' || s['status'] == 'occupied' || s['status'] == 'boarded').length;
          int boardedCount = liveSeats.where((s) => s['status'] == 'boarded').length;
          int totalSeats = int.tryParse(capacity) ?? 54;
          int availableCount = totalSeats - bookedCount;

          return Column(
            children: [
              _buildHeader(widget.routeData, totalSeats, bookedCount, availableCount, boardedCount, isDark),
              _buildFilterSection(liveSeats, isDark),
              if (_isGridView) _buildLegend(),
              Expanded(
                child: _isGridView 
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                        child: _buildBusGrid(context, blueprint, liveSeats, capacity, isDark),
                      )
                    : _buildPassengerList(context, liveSeats, isDark),
              ),
            ],
          );
        },
      ),
    );
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

  Widget _buildFilterSection(List<Map<String, dynamic>> liveSeats, bool isDark) {
    Set<String> stops = {};
    for (var seat in liveSeats) {
      if (seat['pickup'] != null) stops.add(seat['pickup'].toString());
      if (seat['dropoff'] != null) stops.add(seat['dropoff'].toString());
    }
    List<String> sortedStops = stops.toList()..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val.toLowerCase().trim();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by Name or Ticket ID (e.g. RS-1234)',
              hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade400, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.primaryOrange),
              suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStopFilter,
                hint: Text('Filter by Stop (Pickup or Dropoff)', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 13)),
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                icon: const Icon(Icons.location_on, color: AppColors.primaryOrange, size: 20),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Stops', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  ),
                  ...sortedStops.map((stop) => DropdownMenuItem(
                    value: stop,
                    child: Text(stop, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  )),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedStopFilter = val;
                  });
                },
              ),
            ),
          ),
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
          const SizedBox(width: 16),
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(3)),
                child: const Icon(Icons.close, size: 10, color: Colors.white),
              ),
              const SizedBox(width: 6),
              const Text('Blocked', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600)),
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
            bool isReserved = liveData['status'] == 'reserved';
            bool isBlocked = liveData['status'] == 'blocked';
            bool isBoarded = liveData['status'] == 'boarded';

            bool isHighlighted = false;
            bool isDimmed = false;
            
            if (isBooked || isBoarded || isReserved) {
              if (_searchQuery.isNotEmpty) {
                final name = (liveData['passengerName'] ?? '').toString().toLowerCase();
                final ticket = (liveData['ticketCode'] ?? '').toString().toLowerCase();
                if (name.contains(_searchQuery) || ticket.contains(_searchQuery)) {
                  isHighlighted = true;
                }
              }
              
              if (_selectedStopFilter != null) {
                final pickup = liveData['pickup']?.toString();
                final dropoff = liveData['dropoff']?.toString();
                if (pickup != _selectedStopFilter && dropoff != _selectedStopFilter) {
                  isDimmed = true;
                  isHighlighted = false; // Overrule highlight if it doesn't match the stop
                } else if (_searchQuery.isEmpty) {
                  isHighlighted = true; // Highlight if it matches stop filter and no search query is typed
                }
              }
            } else if (_selectedStopFilter != null || _searchQuery.isNotEmpty) {
               // Dim empty seats when a filter is active
               isDimmed = true;
            }

            return _OperatorSeatWidget(
              number: bp.seatNumber,
              isBooked: isBooked,
              isReserved: isReserved,
              isBoarded: isBoarded,
              isBlocked: isBlocked,
              isHighlighted: isHighlighted,
              isDimmed: isDimmed,
              isDark: isDark,
              onTap: () {
                if (isBooked || isReserved || isBoarded) {
                  _showBookingDetails(context, bp.seatNumber, liveData, isDark);
                } else if (isBlocked) {
                  _showBlockSeatDialog(context, 'dummy_schedule_id', bp.seatNumber, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Seat ${bp.seatNumber} is currently available.')),
                  );
                }
              },
              onLongPress: () {
                if (!isBooked && !isReserved && !isBoarded) {
                  _showBlockSeatDialog(context, widget.routeData['id'] ?? 'dummy_schedule_id', bp.seatNumber, isBlocked);
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPassengerList(BuildContext context, List<Map<String, dynamic>> liveSeats, bool isDark) {
    // Filter out empty seats
    final List<Map<String, dynamic>> bookedSeats = liveSeats.where((s) {
      final status = s['status'];
      return ['sold', 'occupied', 'boarded', 'reserved'].contains(status);
    }).toList();

    // Apply search and stop filters if active
    final List<Map<String, dynamic>> displayedSeats = bookedSeats.where((s) {
      bool matchesSearch = true;
      bool matchesStop = true;
      
      if (_searchQuery.isNotEmpty) {
        final name = (s['passengerName'] ?? '').toString().toLowerCase();
        final ticket = (s['ticketCode'] ?? '').toString().toLowerCase();
        matchesSearch = name.contains(_searchQuery) || ticket.contains(_searchQuery);
      }
      
      if (_selectedStopFilter != null) {
        final pickup = s['pickup']?.toString();
        final dropoff = s['dropoff']?.toString();
        matchesStop = (pickup == _selectedStopFilter || dropoff == _selectedStopFilter);
      }
      
      return matchesSearch && matchesStop;
    }).toList();

    if (displayedSeats.isEmpty) {
      return Center(
        child: Text(
          (_searchQuery.isNotEmpty || _selectedStopFilter != null) ? 'No passengers found matching the filters' : 'No passengers booked yet.',
          style: TextStyle(color: isDark ? Colors.white54 : AppColors.textLight, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: displayedSeats.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final seatData = displayedSeats[index];
        final String seatNumber = seatData['seatNumber'] ?? '?';
        final String passengerName = seatData['passengerName'] ?? seatData['passengerId'] ?? 'Unknown';
        final String ticketCode = seatData['ticketCode'] ?? 'N/A';
        final String pickup = seatData['pickup'] ?? 'Pettah';
        final String dropoff = seatData['dropoff'] ?? 'Destination';
        final String status = seatData['status'] ?? 'sold';
        final bool isBoarded = status == 'boarded';
        
        return InkWell(
          onTap: () => _showBookingDetails(context, seatNumber, seatData, isDark),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              boxShadow: [
                if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                // Seat Number Badge
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isBoarded ? Colors.green.withValues(alpha: 0.15) : AppColors.primaryOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isBoarded ? Colors.green.withValues(alpha: 0.3) : AppColors.primaryOrange.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    seatNumber,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isBoarded ? Colors.green : AppColors.primaryOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Passenger Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              passengerName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isBoarded ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isBoarded ? 'BOARDED' : 'BOOKED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isBoarded ? Colors.green : (isDark ? Colors.white70 : Colors.black54),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'TKT: $ticketCode',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.trip_origin, size: 12, color: AppColors.primaryOrange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pickup,
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textLight),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                          ),
                          Expanded(
                            child: Text(
                              dropoff,
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textLight),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBlockSeatDialog(BuildContext context, String scheduleId, String seatNumber, bool isCurrentlyBlocked) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCurrentlyBlocked ? 'Unblock Seat $seatNumber?' : 'Block Seat $seatNumber?'),
        content: Text(isCurrentlyBlocked 
            ? 'This seat will become available for passengers to book again.' 
            : 'Passengers will no longer be able to book this seat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final docRef = FirebaseFirestore.instance.collection('schedules').doc(scheduleId).collection('seats').doc(seatNumber);
              
              if (isCurrentlyBlocked) {
                await docRef.update({'status': 'available'});
              } else {
                await docRef.set({'status': 'blocked', 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: isCurrentlyBlocked ? Colors.green : Colors.red),
            child: Text(isCurrentlyBlocked ? 'Unblock' : 'Block', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
            if (bookingData['ticketCode'] != null) ...[
              _detailRow(Icons.confirmation_number, 'Ticket Code', bookingData['ticketCode'], isDark),
              const SizedBox(height: 16),
            ],
            _detailRow(Icons.person, 'Passenger', bookingData['passengerName'] ?? bookingData['passengerId'] ?? 'Unknown', isDark),
            const SizedBox(height: 16),
            _detailRow(Icons.trip_origin, 'Boarding', bookingData['pickup'] ?? 'Pettah Terminal', isDark),
            const SizedBox(height: 16),
            _detailRow(Icons.location_on, 'Drop-off', bookingData['dropoff'] ?? 'Kaduwela', isDark),
            const SizedBox(height: 32),
            if (bookingData['status'] == 'boarded') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final scheduleId = widget.routeData['id'] ?? 'dummy_schedule_id';
                    await FirebaseFirestore.instance
                        .collection('schedules')
                        .doc(scheduleId)
                        .collection('seats')
                        .doc(seatNumber)
                        .delete();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Passenger at seat $seatNumber has been dropped off.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Drop Off Passenger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
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
  final bool isBlocked;
  final bool isHighlighted;
  final bool isDimmed;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _OperatorSeatWidget({
    required this.number,
    required this.isBooked,
    required this.isReserved,
    required this.isBoarded,
    required this.isBlocked,
    this.isHighlighted = false,
    this.isDimmed = false,
    required this.isDark,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    if (isBlocked) {
      bgColor = Colors.red.shade600;
      textColor = Colors.white;
    } else if (isBoarded) {
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

    return Opacity(
      opacity: isDimmed ? 0.3 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: isHighlighted
                ? Border.all(color: Colors.yellowAccent, width: 3)
                : Border.all(
                    color: isReserved 
                        ? AppColors.primaryOrange 
                        : ((isBooked || isBoarded || isBlocked) ? Colors.transparent : (isDark ? Colors.white10 : Colors.grey.shade200)),
                  ),
            boxShadow: isHighlighted 
                ? [BoxShadow(color: Colors.yellowAccent.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2)]
                : (isReserved ? [BoxShadow(color: AppColors.primaryOrange.withValues(alpha: 0.3), blurRadius: 8)] : null),
          ),
          child: isBlocked
              ? const Icon(Icons.close, color: Colors.white, size: 16)
              : (isBoarded
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      number,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: (isBooked || isReserved) ? FontWeight.bold : FontWeight.w500,
                        color: textColor,
                      ),
                    )),
        ),
      ),
    );
  }
}
