import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ridesync/features/passenger/data/models/route_models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ScheduleModel {
  final String id;
  final String routeId;
  final String busId;
  final DateTime departureTime;
  final String status;
  final int capacity;
  final String? routeName;
  final String? plateNumber;

  ScheduleModel({
    required this.id,
    required this.routeId,
    required this.busId,
    required this.departureTime,
    required this.status,
    required this.capacity,
    this.routeName,
    this.plateNumber,
  });

  factory ScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduleModel(
      id: doc.id,
      routeId: data['routeId'] ?? '',
      busId: data['busId'] ?? '',
      departureTime: (data['departureTime'] as Timestamp).toDate(),
      status: data['status'] ?? 'scheduled',
      capacity: data['capacity'] ?? 54,
      routeName: data['routeName'],
      plateNumber: data['plateNumber'],
    );
  }
}

class BookingProvider extends ChangeNotifier {
  Place? origin;
  Place? destination;
  DateTime selectedDate = DateTime.now();
  
  bool isLoading = false;
  String? errorMessage;
  List<ScheduleModel> availableSchedules = [];
  
  // Seat Management
  ScheduleModel? selectedSchedule;
  List<Map<String, dynamic>> currentSeats = [];
  Set<String> selectedSeatNumbers = {};
  bool isBooking = false;

  void selectSchedule(ScheduleModel schedule) {
    selectedSchedule = schedule;
    selectedSeatNumbers.clear();
    notifyListeners();
  }

  void toggleSeat(String seatNumber) {
    if (selectedSeatNumbers.contains(seatNumber)) {
      selectedSeatNumbers.remove(seatNumber);
    } else {
      // Limit to 4 seats per booking for simplicity
      if (selectedSeatNumbers.length < 4) {
        selectedSeatNumbers.add(seatNumber);
      }
    }
    notifyListeners();
  }

  Stream<List<Map<String, dynamic>>> streamSeats(String scheduleId) {
    return FirebaseFirestore.instance
        .collection('schedules')
        .doc(scheduleId)
        .collection('seats')
        .snapshots()
        .map((snapshot) {
          final seats = snapshot.docs.map((doc) => {
            ...doc.data(),
            'id': doc.id,
          }).toList();
          currentSeats = seats;
          return seats;
        });
  }

  Future<bool> bookSeats(String passengerId) async {
    if (selectedSchedule == null || selectedSeatNumbers.isEmpty) return false;

    isBooking = true;
    notifyListeners();

    try {
      final scheduleRef = FirebaseFirestore.instance.collection('schedules').doc(selectedSchedule!.id);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Check all selected seats are still available
        for (final seatNum in selectedSeatNumbers) {
          final seatRef = scheduleRef.collection('seats').doc(seatNum);
          final seatSnap = await transaction.get(seatRef);
          
          if (!seatSnap.exists || seatSnap.data()?['status'] != 'available') {
            throw Exception('Seat $seatNum is no longer available');
          }
        }

        // 2. Perform updates
        for (final seatNum in selectedSeatNumbers) {
          final seatRef = scheduleRef.collection('seats').doc(seatNum);
          transaction.update(seatRef, {
            'status': 'sold',
            'passengerId': passengerId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // 3. Create booking record
        final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();
        transaction.set(bookingRef, {
          'passengerId': passengerId,
          'scheduleId': selectedSchedule!.id,
          'seats': selectedSeatNumbers.toList(),
          'totalFare': selectedSeatNumbers.length * 1250, // Mock fare
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'confirmed',
        });
      });

      selectedSeatNumbers.clear();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isBooking = false;
      notifyListeners();
    }
  }

  Future<List<String>> searchStops(String query) async {
    if (query.length < 3) return [];
    
    try {
      final Set<String> allResults = {};
      
      // 1. Fetch from Google Places (Sri Lanka restricted)
      final apiKey = dotenv.get('GOOGLE_MAPS_API_KEY');
      final googleUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=$query'
        '&components=country:lk'
        '&key=$apiKey'
      );

      final googleResponse = await http.get(googleUrl);
      if (googleResponse.statusCode == 200) {
        final data = json.decode(googleResponse.body);
        final predictions = data['predictions'] as List;
        for (var p in predictions) {
          allResults.add(p['structured_formatting']['main_text'].toString());
        }
      }

      // 2. Fetch from Firestore routes (Formal Stops)
      final routesSnapshot = await FirebaseFirestore.instance.collection('routes').get();
      for (var doc in routesSnapshot.docs) {
        final data = doc.data();
        
        // Check start/end
        if (data['startPoint'] != null) {
          final start = data['startPoint'].toString().split(',')[0].trim();
          if (start.toLowerCase().contains(query.toLowerCase())) allResults.add(start);
        }
        if (data['endPoint'] != null) {
          final end = data['endPoint'].toString().split(',')[0].trim();
          if (end.toLowerCase().contains(query.toLowerCase())) allResults.add(end);
        }
        
        // Check formal stops
        if (data['stops'] != null && data['stops'] is List) {
          for (var stop in data['stops']) {
            if (stop['name'] != null) {
              final stopName = stop['name'].toString().split(',')[0].trim();
              if (stopName.toLowerCase().contains(query.toLowerCase())) allResults.add(stopName);
            }
          }
        }
      }
      
      return allResults.toList()..sort();
    } catch (e) {
      debugPrint('Error in hybrid search: $e');
      return [];
    }
  }

  void setOrigin(Place place) {
    origin = place;
    notifyListeners();
  }

  void setDestination(Place place) {
    destination = place;
    notifyListeners();
  }

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  // Pre-fill search data from RouteFinder
  void prefillFromFinder(Place? finderOrigin, Place? finderDest) {
    origin = finderOrigin;
    destination = finderDest;
    // Note: We don't change date as per requirement to skip current date if coming from finder
    notifyListeners();
    searchSchedules();
  }

  Future<void> searchSchedules() async {
    if (origin == null || destination == null) {
      errorMessage = 'Please select both origin and destination';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    availableSchedules = [];
    notifyListeners();

    try {
      // Step 1: Find matching routes in Firestore
      final routesSnapshot = await FirebaseFirestore.instance
          .collection('routes')
          .where('isActive', isEqualTo: true)
          .get();
      
      final matchingRouteIds = routesSnapshot.docs.where((doc) {
        final data = doc.data();
        final start = (data['startPoint'] ?? '').toString().toLowerCase();
        final end = (data['endPoint'] ?? '').toString().toLowerCase();
        final name = (data['name'] ?? '').toString().toLowerCase();
        
        final originName = origin!.name.toLowerCase();
        final destName = destination!.name.toLowerCase();
        
        // Match if origin is in start or route name, AND destination is in end or route name
        return (start.contains(originName) || name.contains(originName)) &&
               (end.contains(destName) || name.contains(destName));
      }).map((doc) => doc.id).toList();

      if (matchingRouteIds.isEmpty) {
        errorMessage = 'No routes found for this destination';
        isLoading = false;
        notifyListeners();
        return;
      }

      // Step 2: Fetch schedules for those routes on the selected date
      final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Limit to avoid Firestore whereIn limit (30)
      final limitedRouteIds = matchingRouteIds.take(10).toList();

      final schedulesSnapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('routeId', whereIn: limitedRouteIds)
          .where('departureTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('departureTime', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      // Filter by status 'scheduled' manually to avoid needing a complex composite index
      availableSchedules = schedulesSnapshot.docs
          .map((doc) => ScheduleModel.fromFirestore(doc))
          .where((s) => s.status == 'scheduled')
          .toList();
      
      if (availableSchedules.isEmpty) {
        errorMessage = 'No buses scheduled for this date';
      }
    } catch (e) {
      debugPrint('Firestore Error: $e');
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Access denied. Please ensure you are logged in.';
      } else {
        errorMessage = 'Error searching schedules: ${e.toString().split(']').last}';
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
