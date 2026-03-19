enum UserRole { passenger, operator, guest }

// Data blueprints for Passenger and Operator details
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'Passenger' or 'Operator'
  final int joinYear;
  final int totalRides;
  final double rating;
  final int loyaltyPoints;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.joinYear = 2024,
    this.totalRides = 0,
    this.rating = 5.0,
    this.loyaltyPoints = 0,
  });
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
