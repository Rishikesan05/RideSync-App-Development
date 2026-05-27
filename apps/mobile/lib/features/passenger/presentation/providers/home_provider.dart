import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ridesync/features/passenger/data/models/route_models.dart';

class QuickRouteModel {
  final String id;
  final String title;
  final String origin;
  final String destination;
  final String duration;
  final String fare;
  final String? tag;
  final RecommendationType routeType;

  QuickRouteModel({
    required this.id,
    required this.title,
    required this.origin,
    required this.destination,
    required this.duration,
    required this.fare,
    this.tag,
    this.routeType = RecommendationType.normal,
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

  // Stateful list of favourite routes
  List<Map<String, dynamic>> favouriteRoutes = [
    {'id': 'r1', 'title': 'Work Route', 'origin': 'Pettah', 'destination': 'Maharagama', 'tag': 'Fastest', 'type': RecommendationType.express},
    {'id': 'r2', 'title': 'Home Route', 'origin': 'Kaduwela', 'destination': 'Fort', 'tag': null, 'type': RecommendationType.intercity},
    {'id': 'r3', 'title': 'Gym Route', 'origin': 'Nugegoda', 'destination': 'Bambalapitiya', 'tag': 'Traffic Heavy', 'type': RecommendationType.normal},
    {'id': 'r4', 'title': 'Campus Route', 'origin': 'Dehiwala', 'destination': 'Moratuwa', 'tag': 'Standard', 'type': RecommendationType.normal},
    {'id': 'r5', 'title': 'Weekend Route', 'origin': 'Kottawa', 'destination': 'Battaramulla', 'tag': 'Scenic', 'type': RecommendationType.intercity},
  ];

  Future<void> addFavouriteRoute(String title, String origin, String destination) async {
    final newId = 'r${DateTime.now().millisecondsSinceEpoch}';
    favouriteRoutes.add({
      'id': newId,
      'title': title,
      'origin': origin,
      'destination': destination,
      'tag': 'New',
      'type': RecommendationType.normal,
    });
    
    // Invalidate current routes to force a refetch
    quickRoutes.clear();
    await fetchHomeData();
  }

  Future<void> editFavouriteRoute(String id, String title, String origin, String destination) async {
    final index = favouriteRoutes.indexWhere((r) => r['id'] == id);
    if (index != -1) {
      favouriteRoutes[index] = {
        'id': id,
        'title': title,
        'origin': origin,
        'destination': destination,
        'tag': favouriteRoutes[index]['tag'],
        'type': favouriteRoutes[index]['type'] ?? RecommendationType.normal,
      };
      quickRoutes.clear();
      await fetchHomeData();
    }
  }

  Future<void> deleteFavouriteRoute(String id) async {
    favouriteRoutes.removeWhere((r) => r['id'] == id);
    quickRoutes.clear();
    await fetchHomeData();
  }

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

          // Calculate fare matching FinderProvider (Base 30 + 5 per km)
          final distanceValue = leg['distance']['value']; // meters
          final distanceKm = distanceValue / 1000.0;
          final fare = 30.0 + (distanceKm * 5.0);
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

    final List<QuickRouteModel> liveRoutes = [];

    // Fetch live traffic data for each route
    for (var route in favouriteRoutes) {
      final liveData = await _fetchLiveRouteData(route['origin'] as String, route['destination'] as String);
      
      liveRoutes.add(QuickRouteModel(
        id: route['id'] as String,
        title: route['title'] as String,
        origin: route['origin'] as String,
        destination: route['destination'] as String,
        duration: liveData?['duration'] ?? 'Calculating...',
        fare: liveData?['fare'] ?? 'Estimating...',
        tag: route['tag'] as String?,
        routeType: (route['type'] as RecommendationType?) ?? RecommendationType.normal,
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
