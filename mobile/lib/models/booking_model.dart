// lib/models/booking_model.dart

class TypeBookingModel {
  final String typeBookingId;
  final String typeName;
  final String bookingCode;
  final int? durationHours;

  const TypeBookingModel({
    required this.typeBookingId,
    required this.typeName,
    required this.bookingCode,
    this.durationHours,
  });

  factory TypeBookingModel.fromJson(Map<String, dynamic> json) =>
      TypeBookingModel(
        typeBookingId: json['typeBookingId'] as String? ?? '',
        typeName: json['typeName'] as String? ?? '',
        bookingCode: json['bookingCode'] as String? ?? '',
        durationHours: json['durationHours'] as int?,
      );
}

class VoucherModel {
  final String code;
  final String label;
  final double discountPercent; // 0 nếu discountAmount cố định
  final double? discountAmount; // tiền giảm cố định
  final double minOrderAmount; // tổng đơn tối thiểu

  const VoucherModel({
    required this.code,
    required this.label,
    this.discountPercent = 0,
    this.discountAmount,
    this.minOrderAmount = 0,
  });

  /// Đọc từ bảng Voucher (backend). label lấy từ Description.
  factory VoucherModel.fromJson(Map<String, dynamic> json) => VoucherModel(
        code: json['code'] as String? ?? '',
        label: json['description'] as String? ?? '',
        discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
        discountAmount: (json['discountAmount'] as num?)?.toDouble(),
        minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0,
      );

  /// Tính số tiền giảm thực tế dựa trên tổng đơn (giống backend)
  double calculateDiscount(double total) {
    if (total < minOrderAmount) return 0;
    final discount = discountAmount ?? (total * discountPercent / 100).floorToDouble();
    return discount > total ? total : discount;
  }
}

class BookingModel {
  final int? bookingId;
  final String roomId;
  final String userId;
  final String typeBookingId;
  final DateTime checkIn;
  final DateTime? checkOut;
  final double? totalPrice;
  final String? status;
  final String? voucherCode;
  final double? discountAmount;
  final String? note;

  // Thông tin hiển thị (chỉ có khi đọc từ server)
  final String? roomName;
  final String? roomImageUrl;
  final String? hotelName;
  final String? hotelAddress;
  final String? typeBookingName;
  final String? userFullName;
  final String? userPhone;

  const BookingModel({
    this.bookingId,
    required this.roomId,
    required this.userId,
    required this.typeBookingId,
    required this.checkIn,
    this.checkOut,
    this.totalPrice,
    this.status,
    this.voucherCode,
    this.discountAmount,
    this.note,
    this.roomName,
    this.roomImageUrl,
    this.hotelName,
    this.hotelAddress,
    this.typeBookingName,
    this.userFullName,
    this.userPhone,
  });

  String get formattedCheckIn {
    return '${checkIn.day.toString().padLeft(2, '0')}/${checkIn.month.toString().padLeft(2, '0')}/${checkIn.year} ${checkIn.hour.toString().padLeft(2, '0')}:${checkIn.minute.toString().padLeft(2, '0')}';
  }

  String get formattedCheckOut {
    if (checkOut == null) return 'N/A';
    return '${checkOut!.day.toString().padLeft(2, '0')}/${checkOut!.month.toString().padLeft(2, '0')}/${checkOut!.year} ${checkOut!.hour.toString().padLeft(2, '0')}:${checkOut!.minute.toString().padLeft(2, '0')}';
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final room = json['room'] as Map<String, dynamic>?;
    final hotel = room?['hotel'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;
    final typeBooking = json['typeBooking'] as Map<String, dynamic>?;

    return BookingModel(
      bookingId: json['bookingId'] as int?,
      roomId: room?['roomId'] as String? ?? json['roomId'] as String? ?? '',
      userId: user?['userId'] as String? ?? json['userId'] as String? ?? '',
      typeBookingId: typeBooking?['typeBookingId'] as String? ??
          json['typeBookingId'] as String? ??
          '',
      checkIn: DateTime.parse(json['checkIn'] as String),
      checkOut: json['checkOut'] != null
          ? DateTime.parse(json['checkOut'] as String)
          : null,
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      status: json['status'] as String?,
      voucherCode: json['voucherCode'] as String?,
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      note: json['note'] as String?,
      roomName: room?['nameRoom'] as String?,
      roomImageUrl: room?['imageUrl'] as String?,
      hotelName: hotel?['name'] as String?,
      hotelAddress: hotel?['address'] as String?,
      typeBookingName: typeBooking?['typeName'] as String?,
      userFullName: user?['full_name'] as String? ?? user?['fullName'] as String?,
      userPhone: user?['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'room': {'roomId': roomId},
        'user': {'userId': userId},
        'typeBooking': {'typeBookingId': typeBookingId},
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut?.toIso8601String(),
        'totalPrice': totalPrice,
        'status': status ?? 'Chưa thanh toán',
        'voucherCode': voucherCode,
        'discountAmount': discountAmount,
        'note': note,
      };
}
