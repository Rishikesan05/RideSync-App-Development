import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/ai_assistant_fab.dart';
import '../../widgets/notification_tab.dart';

// Home Dashboard with Search Card, Notification Hub, and Hub Grid
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.jpeg',
                height: 32,
                width: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'RideSync',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.primaryNavy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          const NotificationTab(),
          IconButton(
            icon: Icon(
              Icons.account_circle_outlined,
              color: isDark ? Colors.white : AppColors.primaryNavy,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.padding),
        child: Column(
          children: [
            _buildSearchCard(context, isDark),
            const SizedBox(height: 32),
            _buildHubNetwork(context, isDark),
          ],
        ),
      ),
      floatingActionButton: const AIAssistantFAB(),
    );
  }

  Widget _buildSearchCard(BuildContext context, bool isDark) {
    return Card(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildLocationInput('FROM', Icons.circle_outlined),
            const Divider(height: 32),
            _buildLocationInput('TO', Icons.location_on_outlined),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OPTIMIZE ROUTE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInput(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryOrange),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
            const Text(
              'Select Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHubNetwork(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hub Network',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildHubCard(context, 'Central Hub', Icons.hub_outlined),
            _buildHubCard(
              context,
              'North Point',
              Icons.directions_bus_outlined,
            ),
            _buildHubCard(context, 'East Station', Icons.train_outlined),
            _buildHubCard(
              context,
              'West Terminal',
              Icons.airport_shuttle_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHubCard(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : AppColors.primaryNavy.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isDark ? Colors.white : AppColors.primaryNavy),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
