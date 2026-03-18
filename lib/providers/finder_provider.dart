import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/route_models.dart';
import '../services/route_finder_service.dart';

class FinderProvider with ChangeNotifier {
  final RouteFinderService _routeService = RouteFinderService();

  Place? _origin;
  Place? _destination;
  List<RouteRecommendation> _routes = [];
  RouteRecommendation? _selectedRoute;
  bool _isLoading = false;
  String? _errorMessage;

  List<Place> _suggestions = [];
  bool _isSearchingSuggestions = false;
  String? _lastFocusedField; // 'origin' or 'destination'

  bool _isInitialized = false;
  bool _isConfigValid = false;

  Place? get origin => _origin;
  Place? get destination => _destination;
  List<RouteRecommendation> get routes => _routes;
  RouteRecommendation? get selectedRoute => _selectedRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Place> get suggestions => _suggestions;
  bool get isSearchingSuggestions => _isSearchingSuggestions;
  bool get isInitialized => _isInitialized;
  bool get isConfigValid => _isConfigValid;
  String? get lastFocusedField => _lastFocusedField;

  FinderProvider() {
    _initializeApiKey();
  }

  Future<void> _initializeApiKey() async {
    try {
      const channel = MethodChannel('com.ridesync.ridesync/config');
      debugPrint('FinderProvider: Requesting API config from Platform Channel...');
      
      final String? key = await channel.invokeMethod('getApiKey');
      final String? signature = await channel.invokeMethod('getSignature');

      if (key != null && key.isNotEmpty) {
        apiKey = key;
        if (signature != null && signature.isNotEmpty) {
           RouteFinderService.appSignature = signature;
           debugPrint('FinderProvider: Signature injected: ${signature.substring(0, 5)}...');
        }
        _isConfigValid = true;
        _isInitialized = true;
        _errorMessage = null; // Clear any previous errors
        debugPrint('FinderProvider: API Key injected from Platform: ${key.substring(0, 5)}...');
      } else {
        debugPrint('FinderProvider: Received null or empty key from Platform.');
        _errorMessage = 'API Configuration missing. Please check your setup.';
        _isInitialized = true;
        _isConfigValid = false;
      }
    } catch (e) {
      debugPrint('FinderProvider: Failed to fetch API config: $e');
      _errorMessage = 'Failed to load identity config. Restart app.';
      _isInitialized = true;
    } finally {
      notifyListeners();
    }
  }

  set apiKey(String key) => RouteFinderService.apiKey = key;

  Future<void> fetchSuggestions(String query, String field) async {
    _lastFocusedField = field;
    if (query.trim().length < 3) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    _isSearchingSuggestions = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _suggestions = await _routeService.getAutocompleteSuggestions(query);
      if (_suggestions.isEmpty && query.trim().length > 5) {
        // Only set error if it seems like a real failure vs just no results yet
        _errorMessage = 'No places found for "$query"';
      }
    } catch (e) {
      _errorMessage = 'Error finding locations. Check your connection.';
      debugPrint('Error fetching suggestions: $e');
    } finally {
      _isSearchingSuggestions = false;
      notifyListeners();
    }
  }

  void selectOrigin(Place place) async {
    _origin = place;
    _suggestions = [];
    _errorMessage = null;
    notifyListeners();
    
    // Fetch full details if position is 0,0
    if (place.position.latitude == 0) {
      final details = await _routeService.getPlaceDetails(place.id);
      if (details != null) {
        if (!RouteFinderService.isInsideSriLanka(details.position, address: details.address)) {
          _origin = null;
          _errorMessage = 'Route Finder is currently available only within Sri Lanka.';
          notifyListeners();
          return;
        }
        _origin = details;
        notifyListeners();
      } else {
        // Clearing if details failed
        _origin = null;
        _errorMessage = 'Could not load location details. Try again.';
        notifyListeners();
      }
    } else if (!RouteFinderService.isInsideSriLanka(place.position, address: place.address)) {
       _origin = null;
       _errorMessage = 'Route Finder is currently available only within Sri Lanka.';
       notifyListeners();
    }
  }

  void selectDestination(Place place) async {
    _destination = place;
    _suggestions = [];
    _errorMessage = null;
    notifyListeners();

    if (place.position.latitude == 0) {
      final details = await _routeService.getPlaceDetails(place.id);
      if (details != null) {
        if (!RouteFinderService.isInsideSriLanka(details.position, address: details.address)) {
           _destination = null;
           _errorMessage = 'Route Finder is currently available only within Sri Lanka.';
           notifyListeners();
           return;
        }
        _destination = details;
        notifyListeners();
      } else {
        // Clearing if details failed
        _destination = null;
        _errorMessage = 'Could not load location details. Try again.';
        notifyListeners();
      }
    } else if (!RouteFinderService.isInsideSriLanka(place.position, address: place.address)) {
       _destination = null;
       _errorMessage = 'Route Finder is currently available only within Sri Lanka.';
       notifyListeners();
    }
  }

  void clearOrigin() {
    _origin = null;
    _routes = [];
    _selectedRoute = null;
    _suggestions = [];
    _errorMessage = null;
    notifyListeners();
  }

  void clearDestination() {
    _destination = null;
    _routes = [];
    _selectedRoute = null;
    _suggestions = [];
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuggestions() {
    _suggestions = [];
    notifyListeners();
  }

  void setOrigin(Place place) {
    _origin = place;
    notifyListeners();
  }

  void setDestination(Place place) {
    _destination = place;
    notifyListeners();
  }

  void swapLocations() {
    final temp = _origin;
    _origin = _destination;
    _destination = temp;
    _routes = [];
    _selectedRoute = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> searchRoutes() async {
    if (_origin == null || _destination == null) {
      _errorMessage = 'Please select both origin and destination.';
      notifyListeners();
      return;
    }

    if (!RouteFinderService.isInsideSriLanka(_origin!.position, address: _origin!.address) || 
        !RouteFinderService.isInsideSriLanka(_destination!.position, address: _destination!.address)) {
      _errorMessage = 'Route Finder is currently available only within Sri Lanka.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _routes = [];
    _selectedRoute = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _routes = await _routeService.findRoutes(_origin!, _destination!);
      if (_routes.isEmpty) {
        _errorMessage = 'No fare data available for this district pair yet.';
      } else {
        // Find Fastest as default if available
        _selectedRoute = _routes.firstWhere(
          (r) => r.type == RecommendationType.fastest, 
          orElse: () => _routes.first
        );
      }
    } on FareLookupException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Connection error. Please try again.';
      debugPrint('Error searching routes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectRoute(RouteRecommendation route) {
    _selectedRoute = route;
    notifyListeners();
  }

  void clearSearch() {
    _origin = null;
    _destination = null;
    _routes = [];
    _selectedRoute = null;
    _suggestions = [];
    _errorMessage = null;
    notifyListeners();
  }
}
