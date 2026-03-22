// Data model for Bus details
class BusModel {
  final String busId;
  final String routeId;
  final String operatorName;
  final int totalSeats;

  BusModel({
    required this.busId,
    required this.routeId,
    required this.operatorName,
    required this.totalSeats,
  });
}
