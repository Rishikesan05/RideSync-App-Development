import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class OperatorEarningsScreen extends StatefulWidget {
  const OperatorEarningsScreen({super.key});

  @override
  State<OperatorEarningsScreen> createState() => _OperatorEarningsScreenState();
}

class _OperatorEarningsScreenState extends State<OperatorEarningsScreen> {
  String _selectedTimeframe = 'Week';
  bool _isLoading = true;
  String? _error;

  // Fetched data
  double _totalLifetimeRevenue = 0;
  double _pendingHandover = 0;
  double _awaitingApproval = 0;
  double _deposited = 0;
  List<Map<String, dynamic>> _weeklyData = [];
  List<Map<String, dynamic>> _recentTrips = [];
  int _tripsCompleted = 0;
  String _nextHandoverDate = '';

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }


  Future<void> _fetchEarnings() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.user?.id ?? '';
    final customOpId = auth.user?.operatorId ?? '';

    if (uid.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'User not authenticated.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Set<String> targetIds = {
        uid,
        if (customOpId.isNotEmpty) customOpId,
      };

      // Also try fetching custom operatorId from operators doc if not yet in auth
      if (customOpId.isEmpty) {
        try {
          final opDoc = await FirebaseFirestore.instance.collection('operators').doc(uid).get();
          if (opDoc.exists) {
            final opIdFromDoc = opDoc.data()?['operatorId'] as String?;
            if (opIdFromDoc != null && opIdFromDoc.isNotEmpty) {
              targetIds.add(opIdFromDoc);
            }
          }
        } catch (_) {}
      }

      double totalRevenue = 0;
      int tripsCompleted = 0;
      final List<Map<String, dynamic>> allTrips = [];
      final Set<String> seenScheduleIds = {};

      for (final id in targetIds) {
        try {
          final schedulesSnap = await FirebaseFirestore.instance
              .collection('schedules')
              .where('operatorId', isEqualTo: id)
              .get();

          for (final doc in schedulesSnap.docs) {
            if (seenScheduleIds.contains(doc.id)) continue;
            seenScheduleIds.add(doc.id);

            final data = doc.data();
            final status = data['status'] as String? ?? '';
            final revenue = (data['revenue'] ?? 0).toDouble();

            // Count completed or revenue-bearing trips
            if (status == 'completed' || revenue > 0) {
              totalRevenue += revenue;
              tripsCompleted++;
            }

            DateTime? completedAt;
            if (data['actualEndTime'] is Timestamp) {
              completedAt = (data['actualEndTime'] as Timestamp).toDate();
            } else if (data['updatedAt'] is Timestamp) {
              completedAt = (data['updatedAt'] as Timestamp).toDate();
            } else if (data['departureTime'] is Timestamp) {
              completedAt = (data['departureTime'] as Timestamp).toDate();
            }

            allTrips.add({
              'id': doc.id,
              'routeName': data['routeName'] ?? data['route'] ?? 'Regular Route',
              'plateNumber': data['plateNumber'] ?? data['busNumber'] ?? 'N/A',
              'revenue': revenue,
              'bookedSeatsCount': data['bookedSeatsCount'] ?? data['passengersCount'] ?? 0,
              'completedAt': completedAt,
              'status': status,
            });
          }
        } catch (e) {
          debugPrint('Error fetching schedules for $id: $e');
        }
      }

      // Sort trips newest first
      allTrips.sort((a, b) {
        final DateTime? tA = a['completedAt'];
        final DateTime? tB = b['completedAt'];
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });

      // 2. Build weekly breakdown (last 7 days)
      final weeklyData = _buildWeeklyBreakdown(allTrips);

      // 3. Fetch cash handovers for this operator across all target IDs
      double awaitingApproval = 0;
      double deposited = 0;
      final Set<String> seenHandoverIds = {};

      for (final id in targetIds) {
        try {
          final handoverSnap = await FirebaseFirestore.instance
              .collection('cash_handovers')
              .where('operatorId', isEqualTo: id)
              .get();

          for (final doc in handoverSnap.docs) {
            if (seenHandoverIds.contains(doc.id)) continue;
            seenHandoverIds.add(doc.id);

            final data = doc.data();
            final amount = (data['amount'] ?? 0).toDouble();
            final status = data['status'] as String? ?? '';
            if (status == 'pending_approval' || status == 'pending') {
              awaitingApproval += amount;
            } else if (status == 'approved' || status == 'deposited') {
              deposited += amount;
            }
          }
        } catch (_) {}
      }

      // Pending handover = what hasn't been logged yet
      double pendingHandover = totalRevenue - (awaitingApproval + deposited);
      if (pendingHandover < 0) pendingHandover = 0;

      // Next handover date (every Friday)
      final nextFriday = _nextFriday();

      if (mounted) {
        setState(() {
          _totalLifetimeRevenue = totalRevenue;
          _pendingHandover = pendingHandover;
          _awaitingApproval = awaitingApproval;
          _deposited = deposited;
          _weeklyData = weeklyData;
          _recentTrips = allTrips.take(10).toList();
          _tripsCompleted = tripsCompleted;
          _nextHandoverDate = DateFormat('EEEE, d MMMM').format(nextFriday);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching earnings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load earnings. Pull to refresh.';
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildWeeklyBreakdown(List<Map<String, dynamic>> trips) {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final dayEnd = day.add(const Duration(days: 1));
      final dayLabel = DateFormat('E').format(day);

      double amount = 0;
      for (final trip in trips) {
        final DateTime? completedAt = trip['completedAt'];
        if (completedAt != null && completedAt.isAfter(day.subtract(const Duration(seconds: 1))) && completedAt.isBefore(dayEnd)) {
          amount += (trip['revenue'] as double);
        }
      }

      result.add({'day': dayLabel, 'amount': amount, 'isToday': i == 0});
    }

    return result;
  }

  DateTime _nextFriday() {
    final now = DateTime.now();
    final daysUntilFriday = (DateTime.friday - now.weekday + 7) % 7;
    return now.add(Duration(days: daysUntilFriday == 0 ? 7 : daysUntilFriday));
  }

  List<Map<String, dynamic>> get _displayedTrips {
    if (_selectedTimeframe == 'Today') {
      final today = DateTime.now();
      return _recentTrips.where((t) {
        final DateTime? d = t['completedAt'];
        if (d == null) return false;
        return d.year == today.year && d.month == today.month && d.day == today.day;
      }).toList();
    } else if (_selectedTimeframe == 'Week') {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      return _recentTrips.where((t) {
        final DateTime? d = t['completedAt'];
        return d != null && d.isAfter(weekAgo);
      }).toList();
    }
    return _recentTrips; // Month — show all (up to 10)
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchEarnings,
        color: AppColors.primaryOrange,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchEarnings,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      _buildSliverAppBar(isDark),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBalanceCard(isDark),
                              const SizedBox(height: 8),
                              _buildTimeframeToggle(isDark),
                              const SizedBox(height: 24),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildEarningsBreakdown(isDark),
                                    const SizedBox(height: 24),
                                    _buildChartSection(isDark),
                                    const SizedBox(height: 32),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Recent Trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                                        TextButton(
                                          onPressed: _fetchEarnings,
                                          style: TextButton.styleFrom(foregroundColor: AppColors.primaryOrange),
                                          child: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (_displayedTrips.isEmpty)
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24.0),
                                          child: Text(
                                            'No completed trips in this period.',
                                            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                                          ),
                                        ),
                                      )
                                    else
                                      ..._displayedTrips.map((trip) => _buildTripCard(trip, isDark)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      backgroundColor: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: const FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          'Earnings Overview',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildTimeframeToggle(bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ['Today', 'Week', 'Month'].map((timeframe) {
            final isSelected = _selectedTimeframe == timeframe;
            return GestureDetector(
              onTap: () => setState(() => _selectedTimeframe = timeframe),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isSelected && !isDark ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))] : [],
                ),
                child: Text(
                  timeframe,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : AppColors.textDark)
                        : (isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFFE65100), const Color(0xFFBF360C)]
              : [AppColors.primaryOrange, const Color(0xFFFF7043)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: Colors.white.withValues(alpha: 0.9), size: 16),
                const SizedBox(width: 8),
                Text(
                  'TOTAL LIFETIME REVENUE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LKR', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18, fontWeight: FontWeight.bold, height: 2.2)),
                const SizedBox(width: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _totalLifetimeRevenue),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutQuart,
                  builder: (context, value, child) {
                    final formattedValue = NumberFormat('#,##0').format(value.toInt());
                    return Text(formattedValue, style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, letterSpacing: -1));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pendingHandover <= 0
                ? null
                : () => _showHandoverConfirmation(context, _pendingHandover),
            icon: const Icon(Icons.account_balance_rounded, size: 18),
            label: const Text('Log Cash Handover', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFE65100),
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _nextHandoverDate.isEmpty ? '' : 'Next depot handover: $_nextHandoverDate',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('Trips', '$_tripsCompleted', Icons.route_rounded),
                    Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                    _buildStatCard('Pending', 'LKR ${NumberFormat('#,##0').format(_pendingHandover.toInt())}', Icons.pending_actions_rounded),
                    Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                    _buildStatCard('Status', 'Active', Icons.verified_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showHandoverConfirmation(BuildContext context, double amount) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final operatorId = auth.user?.id ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Handover', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to log a cash handover of LKR ${NumberFormat('#,##0').format(amount)} to the depot?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await FirebaseFirestore.instance.collection('cash_handovers').add({
                    'operatorId': operatorId,
                    'amount': amount,
                    'notes': '',
                    'status': 'pending_approval',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cash handover logged! Awaiting admin approval.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  await _fetchEarnings();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to log handover: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEarningsBreakdown(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildBreakdownCard(
            isDark: isDark,
            title: 'Pending',
            amount: _pendingHandover,
            subtitle: 'Cash in hand',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
          const SizedBox(width: 16),
          if (_awaitingApproval > 0) ...[
            _buildBreakdownCard(
              isDark: isDark,
              title: 'Awaiting',
              amount: _awaitingApproval,
              subtitle: 'Depot approval',
              icon: Icons.access_time_rounded,
              color: Colors.amber,
            ),
            const SizedBox(width: 16),
          ],
          _buildBreakdownCard(
            isDark: isDark,
            title: 'Deposited',
            amount: _deposited,
            subtitle: 'Already handed over',
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard({
    required bool isDark,
    required String title,
    required double amount,
    required String subtitle,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: isDark ? color.withValues(alpha: 0.15) : color.shade50, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color.shade600, size: 16),
              ),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text('LKR ${NumberFormat('#,##0').format(amount)}', style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildChartSection(bool isDark) {
    final maxAmount = _weeklyData.fold<double>(0, (max, d) => d['amount'] > max ? d['amount'].toDouble() : max);
    final effectiveMax = maxAmount > 0 ? maxAmount : 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_selectedTimeframe Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
              if (maxAmount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bar_chart_rounded, color: AppColors.primaryOrange, size: 16),
                      const SizedBox(width: 4),
                      Text('LKR ${NumberFormat('#,##0').format(maxAmount.toInt())} peak', style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 160,
            child: _weeklyData.isEmpty
                ? const Center(child: Text('No data', style: TextStyle(color: AppColors.textLight)))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _weeklyData.map((data) {
                      final double amount = (data['amount'] as num).toDouble();
                      final double heightPercentage = amount / effectiveMax;
                      final bool isToday = data['isToday'] == true;
                      final bool isHighest = amount == maxAmount && maxAmount > 0;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isHighest)
                            Text('Peak', style: TextStyle(fontSize: 10, color: AppColors.primaryOrange, fontWeight: FontWeight.bold, height: 2)),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            width: 28,
                            height: (120 * heightPercentage).clamp(4.0, 120.0),
                            decoration: BoxDecoration(
                              gradient: isHighest
                                  ? const LinearGradient(colors: [AppColors.primaryOrange, Color(0xFFFF8A65)], begin: Alignment.bottomCenter, end: Alignment.topCenter)
                                  : null,
                              color: !isHighest
                                  ? (isDark ? const Color(0xFF334155) : Colors.grey.shade200)
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: isHighest
                                  ? [BoxShadow(color: AppColors.primaryOrange.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                                  : [],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            data['day'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                              color: isToday ? AppColors.primaryOrange : (isDark ? Colors.white54 : Colors.grey.shade500),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip, bool isDark) {
    final DateTime? completedAt = trip['completedAt'];
    final String timeStr = completedAt != null ? DateFormat('MMM d, hh:mm a').format(completedAt) : 'Unknown';
    final double revenue = (trip['revenue'] as num).toDouble();
    final int seats = trip['bookedSeatsCount'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.directions_bus_rounded, color: Colors.green.shade600, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip['routeName'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : AppColors.textDark)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(timeStr, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('${trip['plateNumber']}  •  $seats seats', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+LKR ${NumberFormat('#,##0').format(revenue.toInt())}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Completed', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
