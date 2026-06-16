import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/features/operator/presentation/screens/operator_manage_schedule_screen.dart';

class OperatorRoutesScreen extends StatefulWidget {
  const OperatorRoutesScreen({super.key});

  @override
  State<OperatorRoutesScreen> createState() => _OperatorRoutesScreenState();
}

class _OperatorRoutesScreenState extends State<OperatorRoutesScreen> {
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id;
    final operatorId = auth.user?.operatorId ?? userId;
    if (operatorId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('operatorId', isEqualTo: operatorId)
          .get()
          .timeout(const Duration(seconds: 10));

      List<Map<String, dynamic>> schedules = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        
        DateTime? depTime;
        final rawTime = data['departureTime'];
        if (rawTime is Timestamp) {
          depTime = rawTime.toDate();
        } else if (rawTime is String) {
          depTime = DateTime.tryParse(rawTime);
        }

        schedules.add({
          'id': doc.id,
          'routeId': data['routeId'] ?? 'Unknown',
          'name': data['routeName'] ?? 'Unknown Route',
          'type': data['status']?.toUpperCase() ?? 'SCHEDULED',
          'time': depTime != null 
              ? DateFormat('MMM dd, hh:mm a').format(depTime) 
              : 'Unknown Time',
          'rawTime': depTime, // For sorting
          'bus': data['busPlateNumber'] ?? 'Unknown Bus',
          'stops': 15,
          'isAssigned': true,
        });
      }

      // Sort in Dart to avoid Firestore index errors
      schedules.sort((a, b) {
        final DateTime? timeA = a['rawTime'];
        final DateTime? timeB = b['rawTime'];
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeA.compareTo(timeB);
      });

      if (mounted) {
        setState(() {
          _schedules = schedules;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSchedules,
              color: AppColors.primaryOrange,
              child: SingleChildScrollView(
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
                      if (_schedules.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'No schedules assigned to you yet.',
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                            ),
                          ),
                        )
                      else
                        ..._schedules.map((route) => _buildRouteCard(route, isDark)),
                    ],
                  ),
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
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
    final badgeColor = route['type'] == 'ACTIVE' ? Colors.green : AppColors.primaryOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
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
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor.withOpacity(0.3)),
                      ),
                      child: Text(route['type'], style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Text(route['routeId'], style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(route['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _routeMetric(Icons.access_time, route['time'], isDark),
                    const SizedBox(width: 24),
                    _routeMetric(Icons.directions_bus, route['bus'], isDark),
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
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OperatorManageScheduleScreen(routeData: route),
                      ),
                    );
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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
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
                                        color: AppColors.primaryOrange.withOpacity(0.1),
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
