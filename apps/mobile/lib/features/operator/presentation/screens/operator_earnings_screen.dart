import 'package:flutter/material.dart';
import 'package:ridesync/core/constants.dart';

class OperatorEarningsScreen extends StatefulWidget {
  const OperatorEarningsScreen({super.key});

  @override
  State<OperatorEarningsScreen> createState() => _OperatorEarningsScreenState();
}

class _OperatorEarningsScreenState extends State<OperatorEarningsScreen> {
  // Mock Data
  final int _tripsCompleted = 4;
  final double _hoursOnline = 6.5;

  final List<Map<String, dynamic>> _weeklyData = [
    {'day': 'Mon', 'amount': 12000, 'max': false},
    {'day': 'Tue', 'amount': 14000, 'max': false},
    {'day': 'Wed', 'amount': 9500, 'max': false},
    {'day': 'Thu', 'amount': 18500, 'max': true},
    {'day': 'Fri', 'amount': 14500, 'max': false}, // today
    {'day': 'Sat', 'amount': 0, 'max': false},
    {'day': 'Sun', 'amount': 0, 'max': false},
  ];

  final List<Map<String, dynamic>> _transactions = [
    {'id': 'TX-1204', 'route': 'Route 138 (Kadawatha)', 'time': '2:30 PM', 'amount': 4500.00, 'status': 'Completed'},
    {'id': 'TX-1203', 'route': 'Route 138 (Pettah)', 'time': '11:15 AM', 'amount': 5200.00, 'status': 'Completed'},
    {'id': 'TX-1202', 'route': 'Route 120 (Kesbewa)', 'time': '8:00 AM', 'amount': 4800.00, 'status': 'Completed'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFFD84315) : AppColors.primaryOrange,
        elevation: 0,
        title: const Text(
          'Earnings',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceHeader(isDark),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChartSection(isDark),
                  const SizedBox(height: 32),
                  Text('Recent Payouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                  const SizedBox(height: 16),
                  ..._transactions.map((tx) => _buildTransactionCard(tx, isDark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceHeader(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE65100), // Deep Orange
            Color(0xFFBF360C), // Darker Deep Orange
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE65100).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withValues(alpha: 0.8), size: 18),
              const SizedBox(width: 8),
              Text(
                'TODAY\'S EARNINGS', 
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), 
                  fontSize: 12, 
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LKR', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18, fontWeight: FontWeight.bold, height: 2.2)),
                const SizedBox(width: 8),
                const Text('14,500', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Trips', '$_tripsCompleted', Icons.route_outlined, isDark),
                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                _buildStatCard('Hours', '$_hoursOnline', Icons.schedule, isDark),
                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
                _buildStatCard('Status', 'Active', Icons.check_circle_outline, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildChartSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('This Week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
              Text('LKR 68,500', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryOrange)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _weeklyData.map((data) {
              final double maxAmount = 20000.0;
              final double heightPercentage = (data['amount'] as int) / maxAmount;
              final bool isHighest = data['max'] == true;
              final bool isToday = data['day'] == 'Fri';

              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 120 * heightPercentage + 4, // min height 4
                    decoration: BoxDecoration(
                      color: isHighest ? AppColors.primaryNavy : (isToday ? AppColors.primaryOrange : (isDark ? Colors.white12 : Colors.grey.shade200)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data['day'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? AppColors.primaryOrange : (isDark ? Colors.white54 : Colors.grey),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_downward, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['route'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppColors.textDark)),
                const SizedBox(height: 4),
                Text('${tx['time']} • ${tx['id']}', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${tx['amount'].toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              const SizedBox(height: 4),
              Text(tx['status'], style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
