import 'package:google_maps_flutter/google_maps_flutter.dart';

enum RecommendationType { express, intercity, normal }

class Place {
  final String id;
  final String name;
  final LatLng position;
  final String address;
  final String? districtId;
  final List<String> addressComponents;

  Place({
    required this.id,
    required this.name,
    required this.position,
    required this.address,
    this.districtId,
    this.addressComponents = const [],
  });

  factory Place.fromAutocomplete(Map<String, dynamic> json) {
    // Handle Places API (New) format
    if (json.containsKey('placePrediction')) {
      final prediction = json['placePrediction'];
      return Place(
        id: prediction['placeId'] ?? '',
        name: prediction['text']?['text'] ?? '',
        position: const LatLng(0, 0),
        address: prediction['structuredFormat']?['secondaryText']?['text'] ?? '',
        districtId: null,
        addressComponents: const [],
      );
    }
    
    // Fallback/Legacy format support
    return Place(
      id: json['place_id'] ?? '',
      name: json['structured_formatting']?['main_text'] ?? json['description'] ?? '',
      position: const LatLng(0, 0),
      address: json['structured_formatting']?['secondary_text'] ?? '',
      districtId: null,
      addressComponents: const [],
    );
  }
}

class RouteRecommendation {
  final String id;
  final String title;
  final String duration;
  final String distance;
  final double fare;
  final RecommendationType type;
  final String reason;
  final List<LatLng> polylinePoints;
  final bool isRecommended;
  final String currency;
  final bool hasStoredFare;
  final String? fareSource;

  RouteRecommendation({
    required this.id,
    required this.title,
    required this.duration,
    required this.distance,
    required this.fare,
    required this.type,
    required this.reason,
    required this.polylinePoints,
    this.isRecommended = false,
    this.currency = 'LKR',
    this.hasStoredFare = false,
    this.fareSource,
  });

  RouteRecommendation copyWith({
    String? id,
    String? title,
    String? duration,
    String? distance,
    double? fare,
    RecommendationType? type,
    String? reason,
    List<LatLng>? polylinePoints,
    bool? isRecommended,
    String? currency,
    bool? hasStoredFare,
    String? fareSource,
  }) {
    return RouteRecommendation(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      fare: fare ?? this.fare,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      isRecommended: isRecommended ?? this.isRecommended,
      currency: currency ?? this.currency,
      hasStoredFare: hasStoredFare ?? this.hasStoredFare,
      fareSource: fareSource ?? this.fareSource,
    );
  }

  factory RouteRecommendation.fromDirections(Map<String, dynamic> data, RecommendationType type, String reason) {
    // Basic extraction from Google Directions JSON structure
    final leg = data['legs'][0];
    return RouteRecommendation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: data['summary'] ?? 'Standard Route',
      duration: leg['duration']['text'],
      distance: leg['distance']['text'],
      fare: 0.0, // Calculated separately
      type: type,
      reason: reason,
      polylinePoints: [], // Decoded later
    );
  }

  String get typeLabel {
    switch (type) {
      case RecommendationType.express:
        return 'Express';
      case RecommendationType.intercity:
        return 'Intercity';
      case RecommendationType.normal:
        return 'Normal Service';
    }
  }
}
