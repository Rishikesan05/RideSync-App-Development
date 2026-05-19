import 'package:flutter/material.dart';

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

  factory QuickRouteModel.fromJson(Map<String, dynamic> json) {
    return QuickRouteModel(
      id: json['id'],
      title: json['title'],
      origin: json['origin'],
      destination: json['destination'],
      duration: json['duration'],
      fare: json['fare'],
      tag: json['tag'],
    );
  }
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

  factory HubModel.fromJson(Map<String, dynamic> json) {
    return HubModel(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
    );
  }
}

class HomeProvider extends ChangeNotifier {
  List<QuickRouteModel> quickRoutes = [];
  List<HubModel> hubs = [];
  bool isLoading = false;

  Future<void> fetchHomeData() async {
    // Prevent redundant fetches if already loaded
    if (quickRoutes.isNotEmpty && hubs.isNotEmpty) return;

    isLoading = true;
    notifyListeners();

    // Simulating a network call to the backend API
    await Future.delayed(const Duration(milliseconds: 1500));

    // Mock JSON response from backend
    final mockRoutesResponse = [
      {
        "id": "r1",
        "title": "Work Route",
        "origin": "Pettah",
        "destination": "Maharagama",
        "duration": "18 mins",
        "fare": "Rs. 120",
        "tag": "Fastest"
      },
      {
        "id": "r2",
        "title": "Home Route",
        "origin": "Kaduwela",
        "destination": "Fort",
        "duration": "45 mins",
        "fare": "Rs. 210",
        "tag": null
      }
    ];

    final mockHubsResponse = [
      {
        "id": "h1",
        "title": "Pettah Main\nTerminal",
        "subtitle": "Main hub"
      },
      {
        "id": "h2",
        "title": "Nugegoda Bus\nStand",
        "subtitle": "Junction hub"
      },
      {
        "id": "h3",
        "title": "Maharagama\nTerminal",
        "subtitle": "Regional hub"
      },
      {
        "id": "h4",
        "title": "Kaduwela\nExpressway",
        "subtitle": "Highway interchange"
      }
    ];

    quickRoutes = mockRoutesResponse.map((data) => QuickRouteModel.fromJson(data)).toList();
    hubs = mockHubsResponse.map((data) => HubModel.fromJson(data)).toList();
    
    isLoading = false;
    notifyListeners();
  }
}
