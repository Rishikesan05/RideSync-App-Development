import 'package:flutter/material.dart';
import 'package:ridesync/core/constants.dart';
import 'dart:ui';

class OperatorEarningsScreen extends StatefulWidget {
  const OperatorEarningsScreen({super.key});

  @override
  State<OperatorEarningsScreen> createState() => _OperatorEarningsScreenState();
}

class _OperatorEarningsScreenState extends State<OperatorEarningsScreen> {
  // Navigation State
  String _selectedTimeframe = 'Week'; // 'Today', 'Week', 'Month'

  // Mock Data
  final int _tripsCompleted = 24;
  final double _hoursOnline = 36.5;

  final List<Map<String, dynamic>> _weeklyData = [
    {'day': 'Mon', 'amount': 12000, 'max': false},
    {'day': 'Tue', 'amount': 14000, 'max': false},
    {'day': 'Wed', 'amount': 9500, 'max': false},
    {'day': 'Thu', 'amount': 18500, 'max': true},
    {'day': 'Fri', 'amount': 14500, 'max': false}, // today
    {'day': 'Sat', 'amount': 4000, 'max': false},
    {'day': 'Sun', 'amount': 0, 'max': false},
  ];

  final List<Map<String, dynamic>> _transactions = [
    {'id': 'TX-1204', 'route': 'Route 138 (Kadawatha)', 'time': '2:30 PM', 'amount': 4500.00, 'status': 'Completed', 'type': 'card'},
    {'id': 'TX-1203', 'route': 'Route 138 (Pettah)', 'time': '11:15 AM', 'amount': 5200.00, 'status': 'Completed', 'type': 'cash'},
    {'id': 'TX-1202', 'route': 'Route 120 (Kesbewa)', 'time': '8:00 AM', 'amount': 4800.00, 'status': 'Completed', 'type': 'online'},
    {'id': 'TX-1201', 'route': 'Route 120 (Pettah)', 'time': 'Yesterday', 'amount': 3200.00, 'status': 'Completed', 'type': 'cash'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: CustomScrollView(
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
                        _buildChartSection(isDark),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Payouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(foregroundColor: AppColors.primaryOrange),
                              child: const Text('See All', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._transactions.map((tx) => _buildTransactionCard(tx, isDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                  'TOTAL BALANCE', 
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
                const Text('68,500', style: TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, letterSpacing: -1)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Glassmorphic Stats Row
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
                    _buildStatCard('Hours', '$_hoursOnline', Icons.schedule_rounded),
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
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildChartSection(bool isDark) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: AppColors.primaryOrange, size: 16),
                    SizedBox(width: 4),
                    Text('+12%', style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyData.map((data) {
                final double maxAmount = 20000.0;
                final double heightPercentage = (data['amount'] as int) / maxAmount;
                final bool isHighest = data['max'] == true;
                final bool isToday = data['day'] == 'Fri';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isHighest) 
                      Text('Max', style: TextStyle(fontSize: 10, color: AppColors.primaryOrange, fontWeight: FontWeight.bold, height: 2)),
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

  Widget _buildTransactionCard(Map<String, dynamic> tx, bool isDark) {
    IconData getTxIcon() {
      switch (tx['type']) {
        case 'card': return Icons.credit_card_rounded;
        case 'online': return Icons.language_rounded;
        default: return Icons.payments_rounded;
      }
    }

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
            child: Icon(getTxIcon(), color: Colors.green.shade600, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['route'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : AppColors.textDark)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(tx['time'], style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(tx['id'], style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${tx['amount'].toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tx['status'], 
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
