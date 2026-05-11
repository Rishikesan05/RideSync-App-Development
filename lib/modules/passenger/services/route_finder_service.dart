import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:ridesync/modules/passenger/data/route_models.dart';
import 'package:ridesync/modules/passenger/repositories/route_fare_repository.dart';

class FareLookupException implements Exception {
  const FareLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RouteFinderApiException implements Exception {
  const RouteFinderApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RouteFinderService {
  static String? apiKey;
  static String? appSignature;
  static const String _packageName = 'com.ridesync.ridesync';
  
  final RouteFareRepository _fareRepository = RouteFareRepository();

  static const String _placesNewBaseUrl = 'https://places.googleapis.com/v1/places';
  static const String _routesBaseUrl = 'https://routes.googleapis.com/directions/v2:computeRoutes';

  String _extractApiError(String body, String fallback) {
    try {
      final data = json.decode(body) as Map<String, dynamic>;
      final error = data['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String?;
      final details = error?['details'] as List<dynamic>?;

      if (details != null) {
        for (final detail in details) {
          final map = detail as Map<String, dynamic>;
          final reason = map['reason'] as String?;
          if (reason == 'API_KEY_ANDROID_APP_BLOCKED') {
            return 'This Google Maps key is blocked for Android app requests. Check API key restrictions in Google Cloud Console.';
          }
        }
      }

      return message ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey ?? '',
      'X-Android-Package': _packageName,
    };
    if (appSignature != null) {
      headers['X-Android-Cert'] = appSignature!;
    }
    return headers;
  }

  Future<List<Place>> getAutocompleteSuggestions(String input) async {
    if (apiKey == null || input.isEmpty) return [];

    try {
      final body = {
        'input': input,
        'includedRegionCodes': ['LK'],
      };
      
      final response = await http.post(
        Uri.parse('$_placesNewBaseUrl:autocomplete'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('suggestions')) {
          return (data['suggestions'] as List)
              .map((s) => Place.fromAutocomplete(s))
              .toList();
        }
      } else {
        debugPrint('Autocomplete (New) error: ${response.statusCode} - ${response.body}');
        throw RouteFinderApiException(
          _extractApiError(response.body, 'Place search failed. Check Google API key setup.'),
        );
      }
    } catch (e) {
      if (e is RouteFinderApiException) rethrow;
      debugPrint('Autocomplete (New) exception: $e');
    }
    return [];
  }

  Future<Place?> getPlaceDetails(String placeId) async {
    if (apiKey == null) return null;

    try {
      final headers = _getHeaders();
      // Field mask is required for Place Details (New)
      headers['X-Goog-FieldMask'] = 'id,displayName,formattedAddress,location,addressComponents';

      final response = await http.get(
        Uri.parse('$_placesNewBaseUrl/$placeId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['displayName']?['text'] ?? 'Unknown';
        final address = data['formattedAddress'] ?? '';
        final location = data['location'];
        final addressComponents = (data['addressComponents'] as List<dynamic>? ?? const [])
            .map((component) => component as Map<String, dynamic>)
            .toList(growable: false);

        return Place(
          id: placeId,
          name: displayName,
          position: LatLng(location['latitude'], location['longitude']),
          address: address,
          districtId: _extractDistrictFromComponents(addressComponents),
          addressComponents: addressComponents
              .map((component) => component['longText'] as String? ?? '')
              .where((value) => value.isNotEmpty)
              .toList(growable: false),
        );
      } else {
        debugPrint('Place Details (New) error: ${response.statusCode} - ${response.body}');
        throw RouteFinderApiException(
          _extractApiError(response.body, 'Place details failed. Check Google API key setup.'),
        );
      }
    } catch (e) {
      if (e is RouteFinderApiException) rethrow;
      debugPrint('Place details (New) exception: $e');
    }
    return null;
  }

  String? _extractDistrictFromComponents(List<Map<String, dynamic>> components) {
    for (final component in components) {
      final types = (component['types'] as List<dynamic>? ?? const [])
          .map((type) => type.toString())
          .toList(growable: false);
      if (types.contains('administrative_area_level_2')) {
        return _normalizeDistrictToken(component['longText'] as String? ?? '');
      }
    }

    for (final component in components) {
      final types = (component['types'] as List<dynamic>? ?? const [])
          .map((type) => type.toString())
          .toList(growable: false);
      if (types.contains('locality') || types.contains('administrative_area_level_3')) {
        return _normalizeDistrictToken(component['longText'] as String? ?? '');
      }
    }

    return null;
  }

  String _normalizeDistrictToken(String value) {
    var normalized = value.toLowerCase().trim();
    normalized = normalized.replaceAll(' district', '');
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    normalized = normalized.replaceAll(RegExp(r'_+'), '_');
    return normalized.replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<List<RouteRecommendation>> findRoutes(Place origin, Place destination) async {
    if (apiKey == null) {
      debugPrint('API Key missing.');
      return [];
    }

    try {
      final body = {
        "origin": {
          "location": {
            "latLng": {
              "latitude": origin.position.latitude,
              "longitude": origin.position.longitude
            }
          }
        },
        "destination": {
          "location": {
            "latLng": {
              "latitude": destination.position.latitude,
              "longitude": destination.position.longitude
            }
          }
        },
        "travelMode": "DRIVE",
        "routingPreference": "TRAFFIC_AWARE",
        "computeAlternativeRoutes": true,
        "languageCode": "en-US",
        "units": "METRIC"
      };

      final headers = _getHeaders();
      headers['X-Goog-Fieldmask'] = 'routes.duration,routes.distanceMeters,routes.polyline,routes.description,routes.routeLabels';

      final response = await http.post(
        Uri.parse(_routesBaseUrl),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic>? routes = data['routes'];
        if (routes != null && routes.isNotEmpty) {
          final processed = _processRoutesV2(routes);
          final storedFare = await _fareRepository.getStoredFare(origin, destination);
          
          if (storedFare == null) {
            throw const FareLookupException('No fare data available for this district pair yet.');
          }

          final fareBackedRoutes = <RouteRecommendation>[];
          for (final route in processed) {
            final fareValue = _fareForType(storedFare, route.type);
            if (fareValue == null) {
              continue;
            }

            fareBackedRoutes.add(
              route.copyWith(
                fare: fareValue,
                currency: storedFare.currency,
                hasStoredFare: true,
                fareSource: storedFare.sourceLabel ?? 'Cloud Fare',
              ),
            );
          }

          if (fareBackedRoutes.isEmpty) {
            throw const FareLookupException('No fare data available for this district pair yet.');
          }

          return fareBackedRoutes;
        }
      } else {
        debugPrint('Routes API error: ${response.statusCode} - ${response.body}');
        throw RouteFinderApiException(
          _extractApiError(response.body, 'Failed to fetch routes. Check Google API key setup.'),
        );
      }
    } catch (e) {
      debugPrint('Routes API Exception: $e');
      rethrow;
    }
    return [];
  }

  double? _fareForType(RouteFare storedFare, RecommendationType type) {
    switch (type) {
      case RecommendationType.express:
        return storedFare.expressFare;
      case RecommendationType.intercity:
        return storedFare.intercityFare;
      case RecommendationType.normal:
        return storedFare.normalFare;
    }
  }

  List<RouteRecommendation> _processRoutesV2(List<dynamic> routes) {
    if (routes.isEmpty) return [];
    
    final List<RouteRecommendation> processed = [];
    
    // Sort by duration ascending
    final List<dynamic> sorted = List.from(routes);
    sorted.sort((a, b) => _parseDuration(a['duration']).compareTo(_parseDuration(b['duration'])));

    if (sorted.length >= 3) {
      processed.add(_convertToRecommendationV2(sorted[0], RecommendationType.express));
      processed.add(_convertToRecommendationV2(sorted[1], RecommendationType.intercity));
      processed.add(_convertToRecommendationV2(sorted.last, RecommendationType.normal));
    } else if (sorted.length == 2) {
      processed.add(_convertToRecommendationV2(sorted[0], RecommendationType.express));
      processed.add(_convertToRecommendationV2(sorted[1], RecommendationType.normal));
    } else {
      // If only 1 route, it defaults to Normal as the baseline service
      processed.add(_convertToRecommendationV2(sorted[0], RecommendationType.normal));
    }

    return processed;
  }

  RouteRecommendation _convertToRecommendationV2(Map<String, dynamic> route, RecommendationType type) {
    final durationSeconds = _parseDuration(route['duration']);
    final distanceMeters = (route['distanceMeters'] as int?) ?? 0;
    final distanceKm = distanceMeters / 1000.0;

    String reason = '';
    switch (type) {
      case RecommendationType.express:
        reason = 'Direct Express route via main highways with minimal stops.';
        break;
      case RecommendationType.intercity:
        reason = 'Intercity service on major trunk roads with limited stops.';
        break;
      case RecommendationType.normal:
        reason = 'Normal service stopping at all designated halts and towns.';
        break;
    }

    final polylinePoints = _decodePolyline(route['polyline']['encodedPolyline']);

    return RouteRecommendation(
      id: 'v2_${DateTime.now().microsecondsSinceEpoch}_${route.hashCode}',
      title: route['description'] ?? '${type.name.toUpperCase()} Route',
      duration: _formatDuration(durationSeconds),
      distance: '${distanceKm.toStringAsFixed(1)} km',
      fare: 0,
      type: type,
      reason: reason,
      polylinePoints: polylinePoints,
      isRecommended: type == RecommendationType.express,
    );
  }

  int _parseDuration(String? duration) {
    if (duration == null) return 0;
    // Format is "1234s"
    return int.parse(duration.replaceAll('s', ''));
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  List<LatLng> _decodePolyline(String encoded) {
    // In v3.1.0+, decodePolyline is a static method
    final List<PointLatLng> result = PolylinePoints.decodePolyline(encoded);
    return result.map((p) => LatLng(p.latitude, p.longitude)).toList();
  }

  static bool isInsideSriLanka(LatLng position, {String? address}) {
    // 1. Check if "Sri Lanka" is in the address string (if provided)
    if (address != null && !address.toLowerCase().contains('sri lanka')) {
      return false;
    }

    // 2. Check approximate bounding box for Sri Lanka
    return position.latitude >= 5.8 &&
           position.latitude <= 9.9 &&
           position.longitude >= 79.6 &&
           position.longitude <= 82.0;
  }
}






