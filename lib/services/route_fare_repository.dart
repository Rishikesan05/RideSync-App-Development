import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_models.dart';

class RouteFare {
  final String originDistrictId;
  final String destinationDistrictId;
  final double? fastestFare;
  final double? safestFare;
  final double? economicFare;
  final String currency;
  final String? sourceLabel;

  RouteFare({
    required this.originDistrictId,
    required this.destinationDistrictId,
    required this.fastestFare,
    required this.safestFare,
    required this.economicFare,
    this.currency = 'LKR',
    this.sourceLabel,
  });

  factory RouteFare.fromFirestore(Map<String, dynamic> data) {
    return RouteFare(
      originDistrictId: data['originDistrictId'] ?? data['originId'] ?? '',
      destinationDistrictId: data['destinationDistrictId'] ?? data['destinationId'] ?? '',
      fastestFare: (data['fastestFare'] as num?)?.toDouble(),
      safestFare: (data['safestFare'] as num?)?.toDouble(),
      economicFare: (data['economicFare'] as num?)?.toDouble(),
      currency: data['currency'] ?? 'LKR',
      sourceLabel: data['sourceLabel'],
    );
  }
}

class RouteFareRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Map<String, String> _districtAliases = {
    'ampara': 'ampara',
    'amparai': 'ampara',
    'anuradhapura': 'anuradhapura',
    'mihintale': 'anuradhapura',
    'thambuttegama': 'anuradhapura',
    'badulla': 'badulla',
    'batticaloa': 'batticaloa',
    'colombo': 'colombo',
    'colombo_01': 'colombo',
    'colombo_1': 'colombo',
    'fort': 'colombo',
    'pettah': 'colombo',
    'dehiwala': 'colombo',
    'mount_lavinia': 'colombo',
    'galle': 'galle',
    'galle_town': 'galle',
    'unawatuna': 'galle',
    'hikkaduwa': 'galle',
    'karapitiya': 'galle',
    'habaraduwa': 'galle',
    'gampaha': 'gampaha',
    'hambantota': 'hambantota',
    'jaffna': 'jaffna',
    'jaffna_town': 'jaffna',
    'yalpanam': 'jaffna',
    'nallur': 'jaffna',
    'chunnakam': 'jaffna',
    'chavakachcheri': 'jaffna',
    'point_pedro': 'jaffna',
    'kalutara': 'kalutara',
    'kandy': 'kandy',
    'kandy_city': 'kandy',
    'peradeniya': 'kandy',
    'pilimathalawa': 'kandy',
    'kadugannawa': 'kandy',
    'katugastota': 'kandy',
    'gampola': 'kandy',
    'gelioya': 'kandy',
    'akurana': 'kandy',
    'digana': 'kandy',
    'teldeniya': 'kandy',
    'wattegama': 'kandy',
    'kegalle': 'kegalle',
    'kilinochchi': 'kilinochchi',
    'kurunegala': 'kurunegala',
    'mannar': 'mannar',
    'matale': 'matale',
    'matara': 'matara',
    'matara_town': 'matara',
    'matara_central': 'matara',
    'mirissa': 'matara',
    'dondra': 'matara',
    'dikwella': 'matara',
    'weligama': 'matara',
    'monaragala': 'monaragala',
    'mullaitivu': 'mullaitivu',
    'nuwaraeliya': 'nuwara_eliya',
    'nuwara_eliya': 'nuwara_eliya',
    'nuwara_eliya_town': 'nuwara_eliya',
    'polonnaruwa': 'polonnaruwa',
    'puttalam': 'puttalam',
    'ratnapura': 'ratnapura',
    'trincomalee': 'trincomalee',
    'trinco': 'trincomalee',
    'nilaveli': 'trincomalee',
    'uppuveli': 'trincomalee',
    'kinniya': 'trincomalee',
    'vavuniya': 'vavuniya',
    'vavuniya_town': 'vavuniya',
  };
  static const List<String> _ignoredTokens = [
    'sri lanka',
    'northern province',
    'southern province',
    'western province',
    'eastern province',
    'central province',
    'north western province',
    'north central province',
    'uva province',
    'sabaragamuwa province',
    'province',
    'bus stand',
    'bus station',
    'station',
    'town',
    'city',
    'central',
  ];

  String _normalizeToken(String text) {
    String normalized = text.toLowerCase().trim();

    for (final word in _ignoredTokens) {
      normalized = normalized.replaceAll(word, '');
    }

    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    normalized = normalized.replaceAll(RegExp(r'_+'), '_');
    normalized = normalized.replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized;
  }

  String? _districtFromText(String text) {
    final normalized = _normalizeToken(text);
    if (normalized.isEmpty) return null;
    return _districtAliases[normalized];
  }

  List<String> _extractDistrictCandidates(Place place) {
    final candidates = <String>{};

    void addCandidate(String value) {
      final district = _districtFromText(value);
      if (district != null && district.isNotEmpty) {
        candidates.add(district);
      }
    }

    if (place.districtId != null && place.districtId!.isNotEmpty) {
      candidates.add(place.districtId!);
    }

    addCandidate(place.name);
    addCandidate(place.address);

    for (final component in place.addressComponents) {
      addCandidate(component);
    }

    for (final token in place.address.split(',')) {
      addCandidate(token);
    }

    return candidates.toList(growable: false);
  }

  Future<RouteFare?> getStoredFare(Place origin, Place destination) async {
    try {
      final originDistricts = _extractDistrictCandidates(origin);
      final destinationDistricts = _extractDistrictCandidates(destination);
      final candidates = <String>{};

      for (final originDistrict in originDistricts) {
        for (final destinationDistrict in destinationDistricts) {
          candidates.add('${originDistrict}_$destinationDistrict');
          candidates.add('${destinationDistrict}_$originDistrict');
        }
      }

      for (final docId in candidates) {
        if (docId.isEmpty || docId == '_') continue;
        
        final doc = await _firestore.collection('route_fares').doc(docId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['active'] == true) {
            return RouteFare.fromFirestore(data);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching stored fare: $e');
    }
    return null;
  }
}
