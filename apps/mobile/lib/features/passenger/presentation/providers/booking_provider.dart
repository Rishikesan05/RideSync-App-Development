import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ridesync/features/passenger/data/models/route_models.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A stop entry fetched from the Firestore route document.
class RouteStopEntry {
  final String name;
  final double distFromStartKm;
  final double price;

  const RouteStopEntry({
    required this.name,
    required this.distFromStartKm,
    required this.price,
  });

  factory RouteStopEntry.fromMap(Map<String, dynamic> m) {
    return RouteStopEntry(
      name: (m['name'] ?? '').toString().split(',')[0].trim(),
      distFromStartKm: (m['distFromStartKm'] ?? 0).toDouble(),
      price: (m['price'] ?? 0).toDouble(),
    );
  }
}

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

  // --- Route-based Fare Data (loaded from Firestore on schedule selection) ---
  /// All stops (including origin and destination) with their prices from the route document.
  List<RouteStopEntry> _routeStopEntries = [];

  /// Full-route end price (origin → final destination). This is what the passenger
  /// sees as the face-value "ticket price" on their boarding pass.
  double _endPrice = 0.0;

  /// The price specifically for the passenger's chosen boarding→drop-off leg.
  /// Shown to admin and operator on the booked-seat detail panel.
  double _resolvedStopPrice = 0.0;

  // ── Fare getters ────────────────────────────────────────────────────────────

  /// Full route price (Jaffna → Colombo, e.g. LKR 1 200).
  /// Displayed to the passenger as the ticket face value.
  double get endPrice => _endPrice;

  /// The price for the passenger's actual leg (e.g. Jaffna → Kilinochchi = LKR 100).
  /// Shown to admin / operator when they open a booked seat.
  double get stopPrice => _resolvedStopPrice;

  /// Fare per seat used for payment calculations.
  /// We always charge the passenger the full end price so that the ticket value
  /// matches what is printed on the boarding pass.
  double get farePerSeat => _endPrice > 0 ? _endPrice : _resolvedStopPrice;

  /// Total fare for all selected seats (full ticket price × seats).
  double get totalFare => farePerSeat * selectedSeatNumbers.length;

  /// Reservation fee to be paid upfront (500 LKR per seat, or full fare if < 500).
  double get reservationFeePerSeat => farePerSeat < 500.0 ? farePerSeat : 500.0;

  /// Total reservation fee to pay now.
  double get totalReservationFee => reservationFeePerSeat * selectedSeatNumbers.length;

  /// Balance amount to be paid on the bus.
  double get balanceDue => totalFare - totalReservationFee;

  /// Formatted fare string for display.
  String get formattedFarePerSeat => 'LKR ${farePerSeat.toStringAsFixed(0)}';

  // ── Internal helpers ────────────────────────────────────────────────────────

  /// Normalise a stop name for fuzzy matching (lowercase, first part before comma).
  String _normaliseStop(String val) => val.split(',')[0].trim().toLowerCase();

  /// Find the [RouteStopEntry] whose name best matches [query].
  RouteStopEntry? _findEntry(String query) {
    final q = _normaliseStop(query);
    // Exact match first
    for (final e in _routeStopEntries) {
      if (_normaliseStop(e.name) == q) return e;
    }
    // Partial / contains match
    for (final e in _routeStopEntries) {
      final n = _normaliseStop(e.name);
      if (n.contains(q) || q.contains(n)) return e;
    }
    return null;
  }

  /// Re-resolve the stop price whenever the boarding / drop-off selection changes.
  void _resolveStopFare() {
    if (_routeStopEntries.isEmpty) {
      _resolvedStopPrice = 0.0;
      notifyListeners();
      return;
    }

    final boardingName = selectedBoardingPoint ?? origin?.name ?? '';
    final dropoffName  = selectedDropoffPoint  ?? destination?.name ?? '';

    if (boardingName.isEmpty || dropoffName.isEmpty) {
      _resolvedStopPrice = 0.0;
      notifyListeners();
      return;
    }

    final boardingEntry = _findEntry(boardingName);
    final dropoffEntry  = _findEntry(dropoffName);

    if (dropoffEntry != null && dropoffEntry.price > 0) {
      // The stop price is what the *dropoff* stop costs from the route origin.
      // Subtract boarding stop price so partial legs are priced correctly.
      final boardingPrice = boardingEntry?.price ?? 0.0;
      _resolvedStopPrice = (dropoffEntry.price - boardingPrice).abs();
    } else if (boardingEntry != null) {
      _resolvedStopPrice = boardingEntry.price;
    } else {
      _resolvedStopPrice = 0.0;
    }

    notifyListeners();
  }

  Future<void> selectSchedule(ScheduleModel schedule) async {
    selectedSchedule = schedule;
    selectedSeatNumbers.clear();
    currentRouteStops.clear();
    _routeStopEntries.clear();
    _resolvedStopPrice = 0.0;
    _endPrice = 0.0;
    selectedBoardingPoint = origin?.name;
    selectedDropoffPoint = destination?.name;
    notifyListeners();

    try {
      final routeSnap = await FirebaseFirestore.instance
          .collection('routes')
          .doc(schedule.routeId)
          .get();

      if (routeSnap.exists) {
        final data = routeSnap.data()!;
        final stopNames = <String>[];
        final entries  = <RouteStopEntry>[];

        // ── Origin stop ──
        final originName = (data['origin'] ?? data['startPoint'] ?? '')
            .toString()
            .split(',')
            .first
            .trim();
        if (originName.isNotEmpty) {
          stopNames.add(originName);
          // Origin always costs 0 (it's the starting point of the route)
          entries.add(RouteStopEntry(
            name: originName,
            distFromStartKm: 0,
            price: 0,
          ));
        }

        // ── Intermediate stops ──
        if (data['stops'] is List) {
          for (final stop in (data['stops'] as List)) {
            if (stop['name'] != null) {
              final entry = RouteStopEntry.fromMap(
                Map<String, dynamic>.from(stop as Map),
              );
              if (entry.name.isNotEmpty) {
                stopNames.add(entry.name);
                entries.add(entry);
              }
            }
          }
        }

        // ── Destination stop (end price) ──
        final destName = (data['destination'] ?? data['endPoint'] ?? '')
            .toString()
            .split(',')
            .first
            .trim();
        final rawEndPrice =
            (data['endPrice'] ?? data['price'] ?? 0).toDouble();
        if (destName.isNotEmpty) {
          stopNames.add(destName);
          entries.add(RouteStopEntry(
            name: destName,
            distFromStartKm:
                (data['totalDistanceKm'] ?? 0).toDouble(),
            price: rawEndPrice,
          ));
        }

        _routeStopEntries = entries;
        _endPrice = rawEndPrice;
        currentRouteStops = stopNames.toSet().toList();

        // Resolve fare immediately with pre-selected boarding/dropoff
        _resolveStopFare();
      }
    } catch (e) {
      debugPrint('Failed to fetch route stops: $e');
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
    _resolveStopFare();
  }

  void setDropoffPoint(String? point) {
    selectedDropoffPoint = point;
    _resolveStopFare();
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
        final stops = currentRouteStops.map((s) => s.toLowerCase()).toList();
        String normalize(String val) => val.split(',')[0].trim().toLowerCase();
        
        int findStopIndex(String? stopName) {
            if (stopName == null || stopName.isEmpty) return -1;
            final normalized = normalize(stopName);
            int idx = stops.indexOf(normalized);
            if (idx != -1) return idx;
            for (int i = 0; i < stops.length; i++) {
                if (stops[i].contains(normalized) || normalized.contains(stops[i])) {
                    return i;
                }
            }
            return -1;
        }

        final userOrigin = selectedBoardingPoint ?? origin?.name ?? '';
        final userDest = selectedDropoffPoint ?? destination?.name ?? '';
        int uOIdx = findStopIndex(userOrigin);
        int uDIdx = findStopIndex(userDest);
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
            final data = seatSnap.data() ?? {};
            if (data['status'] != 'available') {
              if (['sold', 'occupied', 'blocked', 'reserved'].contains(data['status'])) {
                 List<dynamic> segments = data['segments'] ?? [];
                 if (segments.isEmpty && data['origin'] != null && data['destination'] != null) {
                     segments.add({'origin': data['origin'], 'destination': data['destination']});
                 }
                 
                 bool hasOverlap = false;
                 if (segments.isEmpty) hasOverlap = true;

                 for (var seg in segments) {
                     int oIdx = findStopIndex(seg['origin']);
                     int dIdx = findStopIndex(seg['destination']);
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
          // ── Fare fields (route-stop based) ──────────────────────────────
          // stopPrice: the price for the passenger's actual boarding→drop-off leg.
          //   Displayed to admin / operator on the booked-seat detail panel.
          'stopPrice': stopPrice.roundToDouble(),
          // endPrice: the full route face value shown to the passenger on their ticket.
          'endPrice': endPrice.roundToDouble(),
          // farePerSeat / totalFare are always the full ticket (endPrice) values.
          'farePerSeat': farePerSeat.roundToDouble(),
          'totalFare': totalFare.roundToDouble(),
          'reservationPaid': totalReservationFee.roundToDouble(),
          'balanceDue': balanceDue.roundToDouble(),
          // fareSource distinguishes route-stop fares from old distance-based ones.
          'fareSource': 'route_stops',
          // ────────────────────────────────────────────────────────────────
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
