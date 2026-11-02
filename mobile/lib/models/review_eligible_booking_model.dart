class ReviewEligibleBookingModel {
  final int bookingId;
  final String roomId;
  final String roomName;
  final String hotelName;
  final DateTime? checkOut;

  const ReviewEligibleBookingModel({
    required this.bookingId,
    required this.roomId,
    required this.roomName,
    required this.hotelName,
    this.checkOut,
  });

  factory ReviewEligibleBookingModel.fromJson(Map<String, dynamic> json) =>
      ReviewEligibleBookingModel(
        bookingId: (json['bookingId'] as num?)?.toInt() ?? 0,
        roomId: json['roomId'] as String? ?? '',
        roomName: json['roomName'] as String? ?? 'Phòng',
        hotelName: json['hotelName'] as String? ?? '',
        checkOut: json['checkOut'] == null
            ? null
            : DateTime.tryParse(json['checkOut'].toString()),
      );
}
