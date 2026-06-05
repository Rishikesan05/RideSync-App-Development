import 'package:flutter/material.dart';
import 'package:ridesync/core/constants.dart';

class OperatorFleetScreen extends StatefulWidget {
  const OperatorFleetScreen({super.key});

  @override
  State<OperatorFleetScreen> createState() => _OperatorFleetScreenState();
}

class _OperatorFleetScreenState extends State<OperatorFleetScreen> {
  // Mock Data
  final int _totalBuses = 12;
  final int _activeBuses = 8;
  final int _maintenanceBuses = 2;

  final List<Map<String, dynamic>> _fleet = [
    {
      'plate': 'ND-2911',
      'route': 'Route 138 (Kadawatha - Pettah)',
      'status': 'Active',
      'driver': 'Kamal Perera',
      'condition': 0.85,
    },
    {
      'plate': 'NC-3942',
      'route': 'Route 120 (Kesbewa - Pettah)',
      'status': 'Idle',
      'driver': 'Unassigned',
      'condition': 0.92,
    },
    {
      'plate': 'NB-1123',
      'route': 'Maintenance',
      'status': 'Maintenance',
      'driver': 'N/A',
      'condition': 0.45,
    },
    {
      'plate': 'ND-5561',
      'route': 'Route 138 (Maharagama - Pettah)',
      'status': 'Active',
      'driver': 'Sunil Silva',
      'condition': 0.78,
    },
  ];

  final List<String> _alerts = [
    'NB-1123: Engine check overdue by 100km',
    'ND-2911: Tire pressure low on rear left',
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
          'My Fleet',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Bus screen coming soon')));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFleetOverview(isDark),
            if (_alerts.isNotEmpty) _buildMaintenanceAlerts(isDark),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Fleet Roster', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
            ),
            const SizedBox(height: 16),
            _buildBusList(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFleetOverview(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white12 : Colors.orange.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_bus_outlined, color: isDark ? Colors.white54 : Colors.orange.shade900, size: 18),
              const SizedBox(width: 8),
              Text(
                'TOTAL FLEET', 
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.orange.shade900, 
                  fontSize: 12, 
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('$_totalBuses', style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontSize: 48, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isDark ? null : Border.all(color: Colors.orange.shade100, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Active', '$_activeBuses', Icons.check_circle_outline, Colors.green, isDark),
                Container(width: 1, height: 30, color: isDark ? Colors.white12 : Colors.grey.shade300),
                _buildStatCard('Idle', '${_totalBuses - _activeBuses - _maintenanceBuses}', Icons.pause_circle_outline, Colors.orange, isDark),
                Container(width: 1, height: 30, color: isDark ? Colors.white12 : Colors.grey.shade300),
                _buildStatCard('Service', '$_maintenanceBuses', Icons.build_circle_outlined, Colors.red, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildMaintenanceAlerts(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Text('Maintenance Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          ..._alerts.map((alert) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Text(alert, style: TextStyle(color: isDark ? Colors.red.shade200 : Colors.red.shade900, fontWeight: FontWeight.w500, fontSize: 13)),
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBusList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _fleet.length,
      itemBuilder: (context, index) {
        return _buildBusCard(_fleet[index], isDark);
      },
    );
  }

  Widget _buildBusCard(Map<String, dynamic> bus, bool isDark) {
    Color statusColor;
    if (bus['status'] == 'Active') {
      statusColor = Colors.green;
    } else if (bus['status'] == 'Maintenance') {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Text(bus['plate'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 1.0)),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: statusColor),
                          const SizedBox(width: 4),
                          Text(bus['status'], style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                Icon(Icons.chevron_right, color: isDark ? Colors.white30 : Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.route_outlined, size: 16, color: isDark ? Colors.white54 : Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(child: Text(bus['route'], style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w500))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: isDark ? Colors.white54 : Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(bus['driver'], style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade800, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Condition', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: bus['condition'],
                      backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        bus['condition'] > 0.8 ? Colors.green : (bus['condition'] > 0.5 ? Colors.orange : Colors.red),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${(bus['condition'] * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
