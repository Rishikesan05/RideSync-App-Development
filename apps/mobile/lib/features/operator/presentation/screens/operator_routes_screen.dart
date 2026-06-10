import 'package:flutter/material.dart';
import 'package:ridesync/core/constants.dart';

class OperatorRoutesScreen extends StatefulWidget {
  const OperatorRoutesScreen({super.key});

  @override
  State<OperatorRoutesScreen> createState() => _OperatorRoutesScreenState();
}

class _OperatorRoutesScreenState extends State<OperatorRoutesScreen> {
  final List<Map<String, dynamic>> _mockRoutes = [
    {
      'id': 'RT-138',
      'name': 'Route 138: Kadawatha - Pettah',
      'type': 'Express',
      'duration': '1h 15m',
      'distance': '18 km',
      'stops': 12,
      'isAssigned': true,
    },
    {
      'id': 'RT-120',
      'name': 'Route 120: Kesbewa - Pettah',
      'type': 'Normal',
      'duration': '1h 45m',
      'distance': '22 km',
      'stops': 24,
      'isAssigned': true,
    },
    {
      'id': 'RT-EX1',
      'name': 'EX01: Makumbura - Galle',
      'type': 'Intercity Highway',
      'duration': '1h 30m',
      'distance': '110 km',
      'stops': 3,
      'isAssigned': false,
    },
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
          'My Schedules',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120, top: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(isDark),
              const SizedBox(height: 24),
              Text('Assigned Schedules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
              const SizedBox(height: 16),
              ..._mockRoutes.where((r) => r['isAssigned'] == true).map((route) => _buildRouteCard(route, isDark)),
              if (_mockRoutes.any((r) => r['isAssigned'] == false)) ...[
                const SizedBox(height: 24),
                Text('New Routes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                const SizedBox(height: 16),
                ..._mockRoutes.where((r) => r['isAssigned'] == false).map((route) => _buildRouteCard(route, isDark)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        style: TextStyle(color: isDark ? Colors.white : AppColors.textDark),
        decoration: InputDecoration(
          hintText: 'Search schedules, destinations...',
          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route, bool isDark) {
    final isExpress = route['type'].toString().toLowerCase().contains('express') || route['type'].toString().toLowerCase().contains('highway');
    final badgeColor = isExpress ? Colors.purple : AppColors.primaryOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(route['type'], style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Text(route['id'], style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(route['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _routeMetric(Icons.timer_outlined, route['duration'], isDark),
                    const SizedBox(width: 24),
                    _routeMetric(Icons.route_outlined, route['distance'], isDark),
                    const SizedBox(width: 24),
                    _routeMetric(Icons.location_on_outlined, '${route['stops']} Stops', isDark),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _showStopsSheet(context, route, isDark),
                  icon: const Icon(Icons.format_list_bulleted, size: 18),
                  label: const Text('View Stops'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryOrange),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manage Schedule Screen Coming Soon')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Manage'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeMetric(IconData icon, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.grey),
        const SizedBox(width: 6),
        Text(value, style: TextStyle(color: isDark ? Colors.white70 : AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showStopsSheet(BuildContext context, Map<String, dynamic> route, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Route Stops', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                  IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: route['stops'],
                itemBuilder: (context, index) {
                  final isLast = index == route['stops'] - 1;
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 30,
                          child: Column(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: index == 0 ? Colors.green : (isLast ? Colors.red : Colors.white),
                                  border: Border.all(color: index == 0 ? Colors.green : (isLast ? Colors.red : AppColors.primaryOrange), width: 4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (!isLast)
                                Expanded(child: Container(width: 2, color: isDark ? Colors.white12 : Colors.grey.shade300)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Stop ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppColors.textDark)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryOrange.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.people, size: 12, color: AppColors.primaryOrange),
                                          const SizedBox(width: 4),
                                          Text('${(index * 7 + 3) % 15 + 1} Booked', style: const TextStyle(color: AppColors.primaryOrange, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Estimated arrival: +${index * 5} mins', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
