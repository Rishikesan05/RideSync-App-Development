import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ridesync/features/passenger/data/models/route_models.dart';
import 'dart:convert';
import 'dart:math' as math;
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

    // departureTime may be stored as a Firestore Timestamp OR as an ISO-8601 String
    DateTime parseDepartureTime(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.parse(raw).toLocal();
      return DateTime.now(); // fallback — should never happen
    }

    return ScheduleModel(
      id: doc.id,
      routeId: data['routeId'] ?? '',
      busId: data['busId'] ?? data['busNumber'] ?? '',
      departureTime: parseDepartureTime(data['departureTime']),
      status: data['status'] ?? 'scheduled',
      capacity: (data['capacity'] ?? data['busCapacity'] ?? 54) is int
          ? (data['capacity'] ?? data['busCapacity'] ?? 54)
          : int.tryParse((data['capacity'] ?? data['busCapacity'] ?? 54).toString()) ?? 54,
      routeName: data['routeName'],
      plateNumber: data['plateNumber'] ?? data['busPlateNumber'],
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
  String? lastGeneratedTicketCode;

  // Route Stops for UI Selection
  List<String> currentRouteStops = [];
  String? selectedBoardingPoint;
  String? selectedDropoffPoint;

  // --- Fare Calculation ---
  static const double _farePerKm = 15.0;
  static const double _minimumFare = 50.0;

  /// Calculate straight-line distance in km using the Haversine formula
  double get distanceKm {
    if (origin == null || destination == null) return 0;
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(destination!.position.latitude - origin!.position.latitude);
    final dLng = _toRadians(destination!.position.longitude - origin!.position.longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(origin!.position.latitude)) *
            math.cos(_toRadians(destination!.position.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    // Multiply by 1.3 to approximate road distance from straight-line
    return (earthRadiusKm * c * 1.3);
  }

  double _toRadians(double deg) => deg * (math.pi / 180);

  /// Calculated fare for a single seat based on distance
  double get farePerSeat {
    final calculated = distanceKm * _farePerKm;
    return calculated < _minimumFare ? _minimumFare : calculated;
  }

  /// Total fare for all selected seats
  double get totalFare => farePerSeat * selectedSeatNumbers.length;

  /// Reservation fee to be paid upfront (500 LKR per seat, or full fare if fare is less than 500)
  double get reservationFeePerSeat => farePerSeat < 500.0 ? farePerSeat : 500.0;

  /// Total reservation fee to pay now
  double get totalReservationFee => reservationFeePerSeat * selectedSeatNumbers.length;

  /// Balance amount to be paid later
  double get balanceDue => totalFare - totalReservationFee;

  /// Formatted fare string for display
  String get formattedFarePerSeat => 'LKR ${farePerSeat.toStringAsFixed(0)}';

  Future<void> selectSchedule(ScheduleModel schedule) async {
    selectedSchedule = schedule;
    selectedSeatNumbers.clear();
    currentRouteStops.clear();
    selectedBoardingPoint = origin?.name;
    selectedDropoffPoint = destination?.name;
    notifyListeners();

    try {
      final routeSnap = await FirebaseFirestore.instance.collection('routes').doc(schedule.routeId).get();
      if (routeSnap.exists) {
        final data = routeSnap.data()!;
        final stops = <String>[];
        if (data['origin'] != null) stops.add(data['origin'].toString().split(',')[0].trim());
        else if (data['startPoint'] != null) stops.add(data['startPoint'].toString().split(',')[0].trim());
        
        if (data['stops'] is List) {
          for (var stop in data['stops']) {
            if (stop['name'] != null) stops.add(stop['name'].toString().split(',')[0].trim());
          }
        }
        
        if (data['destination'] != null) stops.add(data['destination'].toString().split(',')[0].trim());
        else if (data['endPoint'] != null) stops.add(data['endPoint'].toString().split(',')[0].trim());
        
        currentRouteStops = stops.toSet().toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to fetch route stops: $e");
    }
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

  void setBoardingPoint(String? point) {
    selectedBoardingPoint = point;
    notifyListeners();
  }

  void setDropoffPoint(String? point) {
    selectedDropoffPoint = point;
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
        final userOrigin = selectedBoardingPoint ?? origin?.name ?? '';
        final userDest = selectedDropoffPoint ?? destination?.name ?? '';
        int uOIdx = currentRouteStops.indexOf(userOrigin);
        int uDIdx = currentRouteStops.indexOf(userDest);
        if (uOIdx != -1 && uDIdx != -1 && uOIdx > uDIdx) {
            final temp = uOIdx;
            uOIdx = uDIdx;
            uDIdx = temp;
        }

        final Map<String, DocumentSnapshot> seatSnaps = {};

        for (final seatNum in selectedSeatNumbers) {
          final seatRef = scheduleRef.collection('seats').doc(seatNum);
          final seatSnap = await transaction.get(seatRef);
          seatSnaps[seatNum] = seatSnap;
          
          if (seatSnap.exists) {
            final data = seatSnap.data() as Map<String, dynamic>? ?? {};
            if (data['status'] != 'available') {
              if (['sold', 'occupied', 'blocked', 'reserved'].contains(data['status'])) {
                 List<dynamic> segments = data['segments'] ?? [];
                 if (segments.isEmpty && data['origin'] != null && data['destination'] != null) {
                     segments.add({'origin': data['origin'], 'destination': data['destination']});
                 }
                 
                 bool hasOverlap = false;
                 if (segments.isEmpty) hasOverlap = true;

                 for (var seg in segments) {
                     int oIdx = currentRouteStops.indexOf(seg['origin'] ?? '');
                     int dIdx = currentRouteStops.indexOf(seg['destination'] ?? '');
                     if (oIdx != -1 && dIdx != -1) {
                         if (oIdx > dIdx) {
                             final temp = oIdx;
                             oIdx = dIdx;
                             dIdx = temp;
                         }
                         if (uOIdx != -1 && uDIdx != -1) {
                             if (uOIdx < dIdx && uDIdx > oIdx) {
                                 hasOverlap = true;
                             }
                         } else {
                             hasOverlap = true;
                         }
                     } else {
                         hasOverlap = true;
                     }
                 }
                 if (hasOverlap) {
                     throw Exception('Seat $seatNum is no longer available for your selected route');
                 }
              } else {
                 throw Exception('Seat $seatNum is no longer available');
              }
            }
          }
        }

        // 1.5 Generate Ticket Code
        final String ticketCode = 'RS-${math.Random().nextInt(9000) + 1000}';
        lastGeneratedTicketCode = ticketCode;

        // 2. Perform updates
        for (final seatNum in selectedSeatNumbers) {
          final seatRef = scheduleRef.collection('seats').doc(seatNum);
          final seatSnap = seatSnaps[seatNum];
          
          List<dynamic> segments = [];
          if (seatSnap != null && seatSnap.exists) {
              final data = seatSnap.data() as Map<String, dynamic>? ?? {};
              segments = data['segments'] ?? [];
              if (segments.isEmpty && data['origin'] != null && data['destination'] != null) {
                  segments.add({'origin': data['origin'], 'destination': data['destination'], 'passengerId': data['passengerId']});
              }
          }
          
          segments.add({
              'origin': selectedBoardingPoint ?? origin?.name ?? '',
              'destination': selectedDropoffPoint ?? destination?.name ?? '',
              'passengerId': passengerId,
              'ticketCode': ticketCode,
          });

          transaction.set(seatRef, {
            'seatNumber': seatNum,
            'status': 'sold',
            'segments': segments,
            'passengerId': passengerId,
            'ticketCode': ticketCode,
            'updatedAt': FieldValue.serverTimestamp(),
            'origin': segments.first['origin'],
            'destination': segments.last['destination'],
          }, SetOptions(merge: true));
        }

        // 3. Create booking record
        final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();
        transaction.set(bookingRef, {
          'passengerId': passengerId,
          'scheduleId': selectedSchedule!.id,
          'routeId': selectedSchedule!.routeId,
          'busId': selectedSchedule!.busId,
          'seats': selectedSeatNumbers.toList(),
          'origin': selectedBoardingPoint ?? origin?.name ?? '',
          'destination': selectedDropoffPoint ?? destination?.name ?? '',
          'distanceKm': distanceKm.toStringAsFixed(1),
          'farePerSeat': farePerSeat.roundToDouble(),
          'totalFare': totalFare.roundToDouble(),
          'reservationPaid': totalReservationFee.roundToDouble(),
          'balanceDue': balanceDue.roundToDouble(),
          'departureTime': selectedSchedule!.departureTime,
          'routeName': selectedSchedule!.routeName ?? '',
          'plateNumber': selectedSchedule!.plateNumber ?? '',
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'confirmed',
        });
      });

      // We do not clear selectedSeatNumbers here because the success dialog 
      // and BookingConfirmationScreen still need to read these values.
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
        
        // Firestore stores these as 'origin'/'destination' (with fallback to old names)
        final startVal = (data['origin'] ?? data['startPoint'])?.toString();
        if (startVal != null) {
          final start = startVal.split(',')[0].trim();
          if (start.toLowerCase().contains(query.toLowerCase())) allResults.add(start);
        }
        final endVal = (data['destination'] ?? data['endPoint'])?.toString();
        if (endVal != null) {
          final end = endVal.split(',')[0].trim();
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
        // Firestore stores these fields as 'origin' and 'destination'
        final start = (data['origin'] ?? data['startPoint'] ?? '').toString().toLowerCase();
        final end = (data['destination'] ?? data['endPoint'] ?? '').toString().toLowerCase();
        final name = (data['name'] ?? '').toString().toLowerCase();
        // Also check stop names within the route
        final stopsText = (data['stops'] as List? ?? [])
            .map((s) => (s['name'] ?? '').toString().toLowerCase())
            .join(' ');

        final originName = origin!.name.toLowerCase();
        final destName = destination!.name.toLowerCase();

        // Match if origin is in start/stops/name AND destination is in end/stops/name
        final originMatches = start.contains(originName) ||
            name.contains(originName) ||
            stopsText.contains(originName);
        final destMatches = end.contains(destName) ||
            name.contains(destName) ||
            stopsText.contains(destName);

        return originMatches && destMatches;
      }).map((doc) => doc.id).toList();

      if (matchingRouteIds.isEmpty) {
        errorMessage = 'No routes found for this destination';
        isLoading = false;
        notifyListeners();
        return;
      }

      // Step 2: Fetch schedules for those routes
      // NOTE: departureTime may be stored as a Firestore Timestamp OR as an ISO string.
      // To handle both, we fetch ALL schedules for matching routes and filter in-memory by date.
      final limitedRouteIds = matchingRouteIds.take(10).toList();

      final schedulesSnapshot = await FirebaseFirestore.instance
          .collection('schedules')
          .where('routeId', whereIn: limitedRouteIds)
          .get();

      final startOfDay = DateTime(
          selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Accept any non-cancelled status, and filter by selected date in-memory
      const validStatuses = {'scheduled', 'active', 'on_time', 'expired'};
      availableSchedules = schedulesSnapshot.docs
          .map((doc) {
            try {
              return ScheduleModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Skipping malformed schedule ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ScheduleModel>()
          .where((s) {
            final dep = s.departureTime;
            return validStatuses.contains(s.status) &&
                !dep.isBefore(startOfDay) &&
                dep.isBefore(endOfDay);
          })
          .toList()
        ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

      if (availableSchedules.isEmpty) {
        errorMessage = 'No buses found for this route on the selected date';
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
