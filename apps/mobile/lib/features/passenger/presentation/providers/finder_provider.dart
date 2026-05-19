import 'package:flutter/material.dart';
import 'package:ridesync/features/passenger/data/models/route_models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FinderProvider extends ChangeNotifier {
  Place? origin;
  Place? destination;
  String? errorMessage;
  bool isConfigValid = true;
  bool isInitialized = true;
  bool isLoading = false;
  List<Place> suggestions = [];
  String? lastFocusedField;
  List<RouteRecommendation> routes = [];
  RouteRecommendation? selectedRoute;

  void clearOrigin() {
    origin = null;
    notifyListeners();
  }

  void clearDestination() {
    destination = null;
    notifyListeners();
  }

  Future<void> fetchSuggestions(String query, String field) async {
    if (query.isEmpty) {
      suggestions = [];
      notifyListeners();
      return;
    }

    // Clear previous routes when user starts typing a new search
    if (routes.isNotEmpty) {
      routes = [];
    }

    lastFocusedField = field;
    final apiKey = dotenv.get('GOOGLE_MAPS_API_KEY');
    
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=$query'
        '&components=country:lk'
        '&key=$apiKey'
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List;
        
        suggestions = predictions.map((p) => Place(
          id: p['place_id'],
          name: p['structured_formatting']['main_text'],
          address: p['structured_formatting']['secondary_text'] ?? '',
          position: const LatLng(0, 0),
        )).toList();
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  Future<LatLng?> _getPlaceDetails(String placeId) async {
    final apiKey = dotenv.get('GOOGLE_MAPS_API_KEY');
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=geometry'
        '&key=$apiKey'
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = data['result']['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
    } catch (e) {
      debugPrint('Error fetching place details: $e');
    }
    return null;
  }

  void swapLocations() {
    final temp = origin;
    origin = destination;
    destination = temp;
    notifyListeners();
  }

  Future<void> searchFromRawStrings(String originText, String destText) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    // Fetch first suggestion for origin
    await fetchSuggestions(originText, 'origin');
    if (suggestions.isNotEmpty) {
      final p = suggestions.first;
      final latLng = await _getPlaceDetails(p.id!);
      if (latLng != null) {
        origin = Place(id: p.id, name: p.name, address: p.address, position: latLng);
      }
    }

    // Fetch first suggestion for destination
    await fetchSuggestions(destText, 'destination');
    if (suggestions.isNotEmpty) {
      final p = suggestions.first;
      final latLng = await _getPlaceDetails(p.id!);
      if (latLng != null) {
        destination = Place(id: p.id, name: p.name, address: p.address, position: latLng);
      }
    }

    suggestions.clear(); // clear suggestions
    
    // Now search routes if both were resolved
    if (origin != null && destination != null) {
      await searchRoutes();
    } else {
      isLoading = false;
      errorMessage = "Could not resolve locations from text.";
      notifyListeners();
    }
  }

  Future<void> searchRoutes() async {
    if (origin == null || destination == null) {
      errorMessage = 'Please select both origin and destination';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    routes = [];
    notifyListeners();

    final apiKey = dotenv.get('GOOGLE_MAPS_API_KEY');
    
    try {
      String directionsUrl = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin!.position.latitude},${origin!.position.longitude}'
        '&destination=${destination!.position.latitude},${destination!.position.longitude}'
        '&mode=driving'
        '&alternatives=true'
        '&key=$apiKey';

      debugPrint('Fetching routes (with alternatives) from: $directionsUrl');
      var response = await http.get(Uri.parse(directionsUrl));
      var data = json.decode(response.body);
      
      // Fallback: If alternatives=true failed or returned nothing, try without it
      if (data['status'] != 'OK') {
        debugPrint('Alternatives failed (${data['status']}), retrying without alternatives...');
        directionsUrl = directionsUrl.replaceFirst('&alternatives=true', '');
        response = await http.get(Uri.parse(directionsUrl));
        data = json.decode(response.body);
      }

      debugPrint('Directions API Status: ${data['status']}');

      if (response.statusCode == 200 && data['status'] == 'OK') {
        final List<RouteRecommendation> allRecommendations = [];
        final googleRoutes = data['routes'] as List;
        
        debugPrint('Found ${googleRoutes.length} physical routes');

        // Sort physical routes from fastest to slowest based on duration value
        final List sortedRoutes = List.from(googleRoutes);
        sortedRoutes.sort((a, b) {
          final aDur = a['legs'][0]['duration']['value'] as int;
          final bDur = b['legs'][0]['duration']['value'] as int;
          return aDur.compareTo(bDur);
        });

        final count = sortedRoutes.length;
        debugPrint('Found $count sorted physical routes');

        for (var i = 0; i < count; i++) {
          final route = sortedRoutes[i];
          final leg = route['legs'][0];
          
          final distanceMeters = leg['distance']['value'] as int;
          final distanceKm = distanceMeters / 1000.0;
          final durationText = leg['duration']['text'];
          final polyline = route['overview_polyline']['points'];
          final points = _decodePolyline(polyline);
          final summary = route['summary'] ?? 'Main Road';
          
          const double baseFare = 30.0;
          const double ratePerKm = 5.0;
          
          // Custom Route Categorization Rules
          RecommendationType rType;
          double rMult;
          String rLabel;
          double rDurationMult;
          String rReason;
          bool isRecommended;

          if (count >= 3) {
            // Case 1: 3 or more routes returned
            if (i == 0) {
              rType = RecommendationType.express;
              rMult = 2.2;
              rLabel = 'Express (A/C)';
              rDurationMult = 0.8;
              rReason = 'Shortest time with comfortable seating';
              isRecommended = true;
            } else if (i == 1) {
              rType = RecommendationType.intercity;
              rMult = 1.5;
              rLabel = 'Intercity (A/C)';
              rDurationMult = 0.9;
              rReason = 'Balanced commuter route with moderate speed';
              isRecommended = false;
            } else {
              rType = RecommendationType.normal;
              rMult = 1.0;
              rLabel = 'Normal (Non-A/C)';
              rDurationMult = 1.0;
              rReason = 'Standard budget commuter service';
              isRecommended = false;
            }
          } else if (count == 2) {
            // Case 2: Exactly 2 routes returned
            if (i == 0) {
              rType = RecommendationType.express;
              rMult = 2.2;
              rLabel = 'Express (A/C)';
              rDurationMult = 0.8;
              rReason = 'Shortest time with comfortable seating';
              isRecommended = true;
            } else {
              rType = RecommendationType.normal;
              rMult = 1.0;
              rLabel = 'Normal (Non-A/C)';
              rDurationMult = 1.0;
              rReason = 'Standard budget commuter service';
              isRecommended = false;
            }
          } else {
            // Case 3: Only 1 route returned
            rType = RecommendationType.normal;
            rMult = 1.0;
            rLabel = 'Normal (Non-A/C)';
            rDurationMult = 1.0;
            rReason = 'Baseline commuter service';
            isRecommended = false;
          }

          // Calculate duration text based on multiplier
          String adjustedDuration = durationText;
          if (rDurationMult != 1.0) {
            final minutes = _parseDurationToMinutes(durationText);
            final adjustedMinutes = (minutes * rDurationMult).round();
            adjustedDuration = _formatMinutesToDuration(adjustedMinutes);
          }

          allRecommendations.add(_createRoute(
            id: 'route_${i}_${rType.name}',
            title: '$rLabel - Via $summary',
            type: rType,
            distanceKm: distanceKm,
            durationText: adjustedDuration,
            baseFare: baseFare,
            ratePerKm: ratePerKm,
            multiplier: rMult,
            points: points,
            isRecommended: isRecommended,
            reason: rReason,
          ));
        }
        
        routes = allRecommendations;
        if (routes.isNotEmpty) {
          selectedRoute = routes.firstWhere(
            (r) => r.type == RecommendationType.express,
            orElse: () => routes.first,
          );
        }
      } else {
        errorMessage = 'No routes found: ${data['status'] ?? 'Server Error'}';
        if (data['error_message'] != null) {
          errorMessage = '${data['error_message']}';
        }
        debugPrint('API Error: $errorMessage');
      }
    } catch (e) {
      errorMessage = 'Connection error: $e';
      debugPrint('Search Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  RouteRecommendation _createRoute({
    required String id,
    required String title,
    required RecommendationType type,
    required double distanceKm,
    required String durationText,
    required double baseFare,
    required double ratePerKm,
    required double multiplier,
    required List<LatLng> points,
    required bool isRecommended,
    required String reason,
  }) {
    final fare = baseFare + (distanceKm * ratePerKm * multiplier);
    
    return RouteRecommendation(
      id: id,
      title: title,
      description: 'Via A1 Main Road',
      type: type,
      typeLabel: type.name.toUpperCase(),
      fare: fare,
      currency: 'LKR',
      duration: durationText,
      distance: '${distanceKm.toStringAsFixed(1)} km',
      isRecommended: isRecommended,
      hasStoredFare: true,
      fareSource: 'RideSync Fare Engine',
      reason: reason,
      polylinePoints: points,
    );
  }

  int _parseDurationToMinutes(String duration) {
    int totalMinutes = 0;
    final hourMatch = RegExp(r'(\d+)\s*hour').firstMatch(duration);
    final minMatch = RegExp(r'(\d+)\s*min').firstMatch(duration);

    if (hourMatch != null) {
      totalMinutes += int.parse(hourMatch.group(1)!) * 60;
    }
    if (minMatch != null) {
      totalMinutes += int.parse(minMatch.group(1)!);
    }
    
    return totalMinutes == 0 ? 30 : totalMinutes; // Default 30 if parsing fails
  }

  String _formatMinutesToDuration(int totalMinutes) {
    if (totalMinutes < 60) {
      return '$totalMinutes mins';
    }
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (mins == 0) return '$hours hour${hours > 1 ? 's' : ''}';
    return '$hours hour${hours > 1 ? 's' : ''} $mins mins';
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> selectOrigin(Place place) async {
    if (place.id != null) {
      final position = await _getPlaceDetails(place.id!);
      if (position != null) {
        origin = Place(
          id: place.id,
          name: place.name,
          address: place.address,
          position: position,
        );
      }
    } else {
      origin = place;
    }
    suggestions.clear();
    notifyListeners();
  }

  Future<void> selectDestination(Place place) async {
    if (place.id != null) {
      final position = await _getPlaceDetails(place.id!);
      if (position != null) {
        destination = Place(
          id: place.id,
          name: place.name,
          address: place.address,
          position: position,
        );
      }
    } else {
      destination = place;
    }
    suggestions.clear();
    notifyListeners();
  }

  void clearSearch() {
    origin = null;
    destination = null;
    routes.clear();
    suggestions.clear();
    notifyListeners();
  }

  void selectRoute(RouteRecommendation route) {
    selectedRoute = route;
    notifyListeners();
  }
}
