// Data model for Booking details
class BookingModel {
  final String bookingId;
  final String userId;
  final String busId;
  final DateTime bookingDate;
  final int seatNumber;
  final double amount;

  BookingModel({
    required this.bookingId,
    required this.userId,
    required this.busId,
    required this.bookingDate,
    required this.seatNumber,
    required this.amount,
  });
}
