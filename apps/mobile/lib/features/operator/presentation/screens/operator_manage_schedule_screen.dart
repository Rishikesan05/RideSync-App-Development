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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _legendItem('Available', Colors.white, border: Colors.grey.shade300),
            const SizedBox(width: 14),
            _legendItem('Booked', Colors.grey.shade400),
            const SizedBox(width: 14),
            // Boarded
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
            const SizedBox(width: 14),
            // Blocked
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
            const SizedBox(width: 14),
            // Fare Breakdown
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFF6366F1), width: 1),
                      ),
                    ),
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(Icons.call_split, size: 5, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                const Text('Fare Breakdown', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
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

            // Detect fare-breakdown: seat has more than one segment
            final List<dynamic> segments = liveData['segments'] is List
                ? List<dynamic>.from(liveData['segments'] as List)
                : <dynamic>[];
            final bool isFareBreakdown = segments.length > 1;
            
            if (isBooked || isBoarded || isReserved) {
              if (_searchQuery.isNotEmpty) {
                final name = (liveData['passengerName'] ?? '').toString().toLowerCase();
                final ticket = (liveData['ticketCode'] ?? '').toString().toLowerCase();
                // Also search across all segment passenger IDs / ticket codes
                final segText = segments
                    .map((s) => '${s['passengerId'] ?? ''} ${s['ticketCode'] ?? ''}'.toLowerCase())
                    .join(' ');
                if (name.contains(_searchQuery) || ticket.contains(_searchQuery) || segText.contains(_searchQuery)) {
                  isHighlighted = true;
                }
              }
              
              if (_selectedStopFilter != null) {
                final pickup = liveData['pickup']?.toString();
                final dropoff = liveData['dropoff']?.toString();
                // Also check if any segment touches the stop filter
                final segMatchesStop = segments.any((s) =>
                    s['origin']?.toString() == _selectedStopFilter ||
                    s['destination']?.toString() == _selectedStopFilter);
                if (pickup != _selectedStopFilter && dropoff != _selectedStopFilter && !segMatchesStop) {
                  isDimmed = true;
                  isHighlighted = false;
                } else if (_searchQuery.isEmpty) {
                  isHighlighted = true;
                }
              }
            } else if (_selectedStopFilter != null || _searchQuery.isNotEmpty) {
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
              isFareBreakdown: isFareBreakdown,
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
    // Extract segments array — fare-breakdown seats have more than one entry
    final List<dynamic> rawSegments = bookingData['segments'] is List
        ? List<dynamic>.from(bookingData['segments'] as List)
        : <dynamic>[];
    final bool isFareBreakdown = rawSegments.length > 1;

    // Normalise segments: if none stored, synthesise one from the top-level fields
    final List<Map<String, dynamic>> rawMaps = rawSegments.isNotEmpty
        ? rawSegments.map((s) => Map<String, dynamic>.from(s as Map)).toList()
        : [
            {
              'origin': bookingData['origin'] ?? bookingData['pickup'] ?? bookingData['boardingPoint'] ?? '',
              'destination': bookingData['destination'] ?? bookingData['dropoff'] ?? bookingData['alightingPoint'] ?? '',
              'passengerId': bookingData['passengerId'] ?? 'Unknown',
              'ticketCode': bookingData['ticketCode'],
            }
          ];

    // Resolve all field-name aliases so cards always show the right stop names
    final List<Map<String, dynamic>> segments = rawMaps.map((s) {
      String resolveOrigin() {
        for (final k in ['origin', 'pickup', 'boardingPoint', 'from']) {
          final v = s[k]?.toString() ?? '';
          if (v.isNotEmpty) return v;
        }
        return 'Unknown';
      }
      String resolveDest() {
        for (final k in ['destination', 'dropoff', 'alightingPoint', 'to']) {
          final v = s[k]?.toString() ?? '';
          if (v.isNotEmpty) return v;
        }
        return 'Unknown';
      }
      return <String, dynamic>{
        'passengerId': (s['passengerId'] ?? s['userId'] ?? 'Unknown').toString(),
        'ticketCode': s['ticketCode'],
        'origin': resolveOrigin(),
        'destination': resolveDest(),
      };
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: isFareBreakdown ? 0.75 : 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── drag handle ──────────────────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── header ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seat number badge
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isFareBreakdown
                              ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                              : [AppColors.primaryOrange, const Color(0xFFC9731A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isFareBreakdown ? const Color(0xFF6366F1) : AppColors.primaryOrange).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        seatNumber,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seat $seatNumber',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Booking type badge
                              _bookingTypeBadge(isFareBreakdown),
                              const SizedBox(width: 8),
                              // Status badge
                              _statusBadge(bookingData['status']?.toString() ?? 'unknown'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (isFareBreakdown) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: const Color(0xFF6366F1).withValues(alpha: 0.8)),
                      const SizedBox(width: 6),
                      Text(
                        '${segments.length} journeys share this seat',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),
              Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),

              // ── scrollable body ──────────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  children: [
                    // Journey cards
                    ...segments.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final seg = entry.value;
                      return _journeyCard(
                        context: context,
                        index: idx,
                        totalSegments: segments.length,
                        segment: seg,
                        isFareBreakdown: isFareBreakdown,
                        isDark: isDark,
                      );
                    }),

                    const SizedBox(height: 8),

                    // Booked At (top-level)
                    if (bookingData['updatedAt'] != null || bookingData['bookedAt'] != null) ...[
                      _detailRow(
                        Icons.access_time,
                        'Last Updated',
                        _formatTimestamp(bookingData['updatedAt'] ?? bookingData['bookedAt']),
                        isDark,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Drop-off action for boarded seats
                    if (bookingData['status'] == 'boarded') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Drop Off Passenger', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
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
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a card for a single journey segment.
  Widget _journeyCard({
    required BuildContext context,
    required int index,
    required int totalSegments,
    required Map<String, dynamic> segment,
    required bool isFareBreakdown,
    required bool isDark,
  }) {
    final Color accentColor = isFareBreakdown
        ? const Color(0xFF6366F1)
        : AppColors.primaryOrange;
    final String passengerId = segment['passengerId']?.toString() ?? 'Unknown';
    final String? ticketCode = segment['ticketCode']?.toString();
    final String origin = segment['origin']?.toString() ?? 'Unknown';
    final String destination = segment['destination']?.toString() ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: isFareBreakdown ? 0.4 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(
                  isFareBreakdown ? Icons.call_split : Icons.confirmation_number_outlined,
                  color: accentColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isFareBreakdown
                      ? 'Journey ${index + 1} of $totalSegments'
                      : 'Booking Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          // Card body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(Icons.person_outline, 'Passenger', passengerId, isDark),
                const SizedBox(height: 12),
                if (ticketCode != null) ...[
                  _detailRow(Icons.confirmation_number, 'Ticket Code', ticketCode, isDark),
                  const SizedBox(height: 12),
                ],
                // Boarding → Drop-off card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.trip_origin, size: 11, color: accentColor),
                              const SizedBox(width: 4),
                              Text('Boarding', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                            ]),
                            const SizedBox(height: 3),
                            Text(origin, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.textDark), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: Icon(Icons.arrow_forward, size: 13, color: accentColor),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                              Text('Drop-off', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                              const SizedBox(width: 4),
                              Icon(Icons.location_on, size: 11, color: accentColor),
                            ]),
                            const SizedBox(height: 3),
                            Text(destination, textAlign: TextAlign.right, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.textDark), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Badge indicating whether a booking is Fare Breakdown or Normal.
  Widget _bookingTypeBadge(bool isFareBreakdown) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isFareBreakdown
            ? const Color(0xFF6366F1).withValues(alpha: 0.15)
            : Colors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isFareBreakdown
              ? const Color(0xFF6366F1).withValues(alpha: 0.4)
              : Colors.teal.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFareBreakdown ? Icons.call_split : Icons.check_circle_outline,
            size: 11,
            color: isFareBreakdown ? const Color(0xFF6366F1) : Colors.teal,
          ),
          const SizedBox(width: 4),
          Text(
            isFareBreakdown ? 'FARE BREAKDOWN' : 'NORMAL BOOKING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isFareBreakdown ? const Color(0xFF6366F1) : Colors.teal,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Badge showing seat occupancy status.
  Widget _statusBadge(String status) {
    Color color;
    if (status == 'boarded') {
      color = Colors.green;
    } else if (status == 'reserved') {
      color = AppColors.primaryOrange;
    } else {
      color = Colors.blue.shade400;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 12)),
              Text(value, style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    DateTime date;
    if (timestamp.runtimeType.toString() == 'Timestamp') {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return 'Unknown';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
  /// True when this seat is shared by multiple passengers (fare-breakdown booking).
  final bool isFareBreakdown;
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
    this.isFareBreakdown = false,
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isFareBreakdown && !isBlocked && !isBoarded
                    ? const Color(0xFF6366F1).withValues(alpha: 0.55)
                    : bgColor,
                borderRadius: BorderRadius.circular(8),
                border: isHighlighted
                    ? Border.all(color: Colors.yellowAccent, width: 3)
                    : isFareBreakdown && !isBlocked && !isBoarded
                        ? Border.all(color: const Color(0xFF6366F1), width: 1.5)
                        : Border.all(
                            color: isReserved
                                ? AppColors.primaryOrange
                                : ((isBooked || isBoarded || isBlocked)
                                    ? Colors.transparent
                                    : (isDark ? Colors.white10 : Colors.grey.shade200)),
                          ),
                boxShadow: isHighlighted
                    ? [BoxShadow(color: Colors.yellowAccent.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2)]
                    : isFareBreakdown && !isBlocked && !isBoarded
                        ? [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.35), blurRadius: 8)]
                        : (isReserved
                            ? [BoxShadow(color: AppColors.primaryOrange.withValues(alpha: 0.3), blurRadius: 8)]
                            : null),
              ),
              child: isBlocked
                  ? const Icon(Icons.close, color: Colors.white, size: 16)
                  : (isBoarded
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          number,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: (isBooked || isReserved || isFareBreakdown) ? FontWeight.bold : FontWeight.w500,
                            color: isFareBreakdown && !isBlocked && !isBoarded ? Colors.white : textColor,
                          ),
                        )),
            ),
            // Small fare-breakdown indicator badge in the top-right corner
            if (isFareBreakdown && !isBlocked)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.call_split, size: 7, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
