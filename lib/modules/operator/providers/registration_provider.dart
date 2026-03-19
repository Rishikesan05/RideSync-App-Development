import 'package:flutter/material.dart';

// Manages 3-Step Driver registration data
class RegistrationProvider with ChangeNotifier {
  // Step 1: Personal Info
  String name = '';
  String email = '';
  String phone = '';
  // Document paths (placeholders)
  String nicFront = '';
  String nicBack = '';
  String licenseFront = '';
  String licenseBack = '';

  // Step 2: Certifications
  String heavyVehicleLicense = '';
  String yearOfIssuance = '';
  String medicalCertificate = '';
  String trainingCertificate = '';

  // Step 3: Signature
  String signaturePath = '';

  void updateStep1({required String n, required String e, required String p}) {
    name = n;
    email = e;
    phone = p;
    notifyListeners();
  }

  void updateStep2({required String hv, required String year}) {
    heavyVehicleLicense = hv;
    yearOfIssuance = year;
    notifyListeners();
  }

  void setSignature(String path) {
    signaturePath = path;
    notifyListeners();
  }
}
