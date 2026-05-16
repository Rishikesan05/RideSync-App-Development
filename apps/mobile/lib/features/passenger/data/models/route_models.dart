import 'package:google_maps_flutter/google_maps_flutter.dart';

enum RecommendationType { express, intercity, normal }

class Place {
  final String? id;
  final String name;
  final String address;
  final LatLng position;

  Place({this.id, required this.name, required this.address, required this.position});
}

class RouteRecommendation {
  final String id;
  final String title;
  final String description;
  final RecommendationType type;
  final String typeLabel;
  final double fare;
  final String currency;
  final String duration;
  final String distance;
  final bool isRecommended;
  final bool hasStoredFare;
  final String fareSource;
  final String reason;
  final List<LatLng> polylinePoints;

  RouteRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.typeLabel,
    required this.fare,
    required this.currency,
    required this.duration,
    required this.distance,
    required this.isRecommended,
    required this.hasStoredFare,
    required this.fareSource,
    required this.reason,
    required this.polylinePoints,
  });
}
