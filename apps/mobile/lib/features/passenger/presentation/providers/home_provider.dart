import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class QuickRouteModel {
  final String id;
  final String title;
  final String origin;
  final String destination;
  final String duration;
  final String fare;
  final String? tag;

  QuickRouteModel({
    required this.id,
    required this.title,
    required this.origin,
    required this.destination,
    required this.duration,
    required this.fare,
    this.tag,
  });
}

class HubModel {
  final String id;
  final String title;
  final String subtitle;

  HubModel({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

class HomeProvider extends ChangeNotifier {
  List<QuickRouteModel> quickRoutes = [];
  List<HubModel> hubs = [];
  bool isLoading = false;

  Future<Map<String, String>?> _fetchLiveRouteData(String origin, String destination) async {
    final apiKey = dotenv.get('GOOGLE_MAPS_API_KEY');
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${Uri.encodeComponent('$origin, Sri Lanka')}'
        '&destination=${Uri.encodeComponent('$destination, Sri Lanka')}'
        '&mode=driving'
        '&key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final leg = data['routes'][0]['legs'][0];
          
          // Format duration (e.g., "18 mins")
          String durationText = leg['duration']['text'];
          if (durationText.contains('min') && !durationText.contains('mins')) {
            durationText = durationText.replaceAll('min', 'mins');
          }

          // Calculate fare based on distance (Base 100 + 80 per km)
          final distanceValue = leg['distance']['value']; // meters
          final distanceKm = distanceValue / 1000.0;
          final fare = 100 + (distanceKm * 80);
          final roundedFare = (fare / 10).round() * 10; // Round to nearest 10

          return {
            'duration': durationText,
            'fare': 'Rs. $roundedFare',
          };
        }
      }
    } catch (e) {
      debugPrint('Error fetching live route: $e');
    }
    return null;
  }

  Future<void> fetchHomeData() async {
    if (quickRoutes.isNotEmpty && hubs.isNotEmpty) return;

    isLoading = true;
    notifyListeners();

    // The hardcoded favorite routes for this user
    final savedRoutes = [
      {'id': 'r1', 'title': 'Work Route', 'origin': 'Pettah', 'destination': 'Maharagama', 'tag': 'Fastest'},
      {'id': 'r2', 'title': 'Home Route', 'origin': 'Kaduwela', 'destination': 'Fort', 'tag': null},
    ];

    final List<QuickRouteModel> liveRoutes = [];

    // Fetch live traffic data for each route
    for (var route in savedRoutes) {
      final liveData = await _fetchLiveRouteData(route['origin']!, route['destination']!);
      
      liveRoutes.add(QuickRouteModel(
        id: route['id']!,
        title: route['title']!,
        origin: route['origin']!,
        destination: route['destination']!,
        duration: liveData?['duration'] ?? 'Calculating...',
        fare: liveData?['fare'] ?? 'Estimating...',
        tag: route['tag'],
      ));
    }

    quickRoutes = liveRoutes;

    // Load Hubs
    hubs = [
      HubModel(id: "h1", title: "Pettah Main\nTerminal", subtitle: "Main hub"),
      HubModel(id: "h2", title: "Nugegoda Bus\nStand", subtitle: "Junction hub"),
      HubModel(id: "h3", title: "Maharagama\nTerminal", subtitle: "Regional hub"),
      HubModel(id: "h4", title: "Kaduwela\nExpressway", subtitle: "Highway interchange"),
    ];
    
    isLoading = false;
    notifyListeners();
  }
}
