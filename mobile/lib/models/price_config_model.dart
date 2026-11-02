// lib/models/price_config_model.dart

import 'room_model.dart';

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

  Map<String, dynamic> toJson() => {
        'typeBookingId': typeBookingId,
        'typeName': typeName,
        'bookingCode': bookingCode,
        'durationHours': durationHours,
      };
}

class PriceConfigModel {
  final int? priceConfigId;
  final TypeRoomModel? typeRoom;
  final TypeBookingModel? typeBooking;
  final double price;

  const PriceConfigModel({
    this.priceConfigId,
    this.typeRoom,
    this.typeBooking,
    required this.price,
  });

  factory PriceConfigModel.fromJson(Map<String, dynamic> json) =>
      PriceConfigModel(
        priceConfigId: json['priceConfigId'] as int?,
        typeRoom: json['typeRoom'] != null
            ? TypeRoomModel.fromJson(json['typeRoom'] as Map<String, dynamic>)
            : null,
        typeBooking: json['typeBooking'] != null
            ? TypeBookingModel.fromJson(
                json['typeBooking'] as Map<String, dynamic>)
            : null,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        if (priceConfigId != null) 'priceConfigId': priceConfigId,
        if (typeRoom != null) 'typeRoom': typeRoom!.toJson(),
        if (typeBooking != null) 'typeBooking': typeBooking!.toJson(),
        'price': price,
      };
}
