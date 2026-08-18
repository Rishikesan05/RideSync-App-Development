enum UserRole { passenger, operator, guest }

// Data blueprints for Passenger and Operator details
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'Passenger' or 'Operator'
  final String? operatorType; // 'driver' or 'conductor' (only for Operator)
  final String? operatorId; // Custom operator ID (e.g., RSOP2002)
  final int joinYear;
  final int totalRides;
  final double rating;
  final int loyaltyPoints;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    required this.role,
    this.operatorType,
    this.operatorId,
    this.joinYear = 2024,
    this.totalRides = 0,
    this.rating = 5.0,
    this.loyaltyPoints = 0,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    int? totalRides,
    double? rating,
    int? loyaltyPoints,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      operatorType: operatorType,
      operatorId: operatorId,
      joinYear: joinYear,
      totalRides: totalRides ?? this.totalRides,
      rating: rating ?? this.rating,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
    );
  }
}

class OperatorModel extends UserModel {
  final String licenseNumber;

  OperatorModel({
    required super.id,
    required super.name,
    required super.email,
    required this.licenseNumber,
    super.joinYear = 2024,
    super.totalRides = 0,
    super.rating = 5.0,
    super.loyaltyPoints = 0,
  }) : super(role: 'Operator');
}
