// lib/models/room_model.dart

class TypeRoomModel {
  final String typeRoomId;
  final String typeRoom;
  final double? pricePerHour;

  const TypeRoomModel({
    required this.typeRoomId,
    required this.typeRoom,
    this.pricePerHour,
  });

  factory TypeRoomModel.fromJson(Map<String, dynamic> json) => TypeRoomModel(
        typeRoomId: json['typeRoomId'] as String? ?? '',
        typeRoom: json['typeRoom'] as String? ?? '',
        pricePerHour: (json['pricePerHour'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'typeRoomId': typeRoomId,
        'typeRoom': typeRoom,
        if (pricePerHour != null) 'pricePerHour': pricePerHour,
      };
}

class HotelModel {
  final String hotelId;
  final String name;
  final String address;
  final String? phone;
  final String? imageUrl;
  final int? countRoom;
  final String? city;

  const HotelModel({
    required this.hotelId,
    required this.name,
    required this.address,
    this.phone,
    this.imageUrl,
    this.countRoom,
    this.city,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) => HotelModel(
        hotelId: (json['hotelId'] as String? ?? '').trim(),
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String?,
        imageUrl: json['imageUrl'] as String?,
        countRoom: json['countRoom'] as int?,
        city: json['city'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'hotelId': hotelId,
        'name': name,
        'address': address,
        if (phone != null) 'phone': phone,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (countRoom != null) 'countRoom': countRoom,
        if (city != null) 'city': city,
      };
}

class PriceOptionModel {
  final String typeBookingId;
  final String typeName;
  final String bookingCode;
  final int? durationHours;
  final double price;

  const PriceOptionModel({
    required this.typeBookingId,
    required this.typeName,
    required this.bookingCode,
    this.durationHours,
    required this.price,
  });

  factory PriceOptionModel.fromJson(Map<String, dynamic> json) =>
      PriceOptionModel(
        typeBookingId: json['typeBookingId'] as String? ?? '',
        typeName: json['typeName'] as String? ?? '',
        bookingCode: json['bookingCode'] as String? ?? '',
        durationHours: (json['durationHours'] as num?)?.toInt(),
        price: (json['price'] as num?)?.toDouble() ?? 0,
      );
}

class ReviewModel {
  final int reviewId;
  final int bookingId;
  final int rating;
  final String? comment;
  final String reviewerName;
  final DateTime? createdAt;

  const ReviewModel({
    required this.reviewId,
    required this.bookingId,
    required this.rating,
    this.comment,
    required this.reviewerName,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        reviewId: (json['reviewId'] as num?)?.toInt() ?? 0,
        bookingId: (json['bookingId'] as num?)?.toInt() ?? 0,
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        comment: json['comment'] as String?,
        reviewerName: json['reviewerName'] as String? ?? 'Khách hàng',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );
}

class RoomModel {
  final String roomId;
  final String nameRoom;
  final TypeRoomModel? typeRoom;
  final String? status;
  final HotelModel? hotel;
  final String? imageUrl;
  final String? description;
  final String? amenities;
  final double averageRating;
  final int reviewCount;
  final List<PriceOptionModel> priceOptions;
  final List<ReviewModel> reviews;

  const RoomModel({
    required this.roomId,
    required this.nameRoom,
    this.typeRoom,
    this.status,
    this.hotel,
    this.imageUrl,
    this.description,
    this.amenities,
    this.averageRating = 0,
    this.reviewCount = 0,
    this.priceOptions = const [],
    this.reviews = const [],
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
        roomId: json['roomId'] as String? ?? '',
        nameRoom: json['nameRoom'] as String? ?? '',
        typeRoom: json['typeRoom'] != null
            ? TypeRoomModel.fromJson(json['typeRoom'] as Map<String, dynamic>)
            : null,
        status: json['status'] as String?,
        hotel: json['hotel'] != null
            ? HotelModel.fromJson(json['hotel'] as Map<String, dynamic>)
            : null,
        imageUrl: json['imageUrl'] as String?,
        description: json['description'] as String?,
        amenities: json['amenities'] as String?,
        averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        priceOptions: (json['priceOptions'] as List<dynamic>? ?? const [])
            .map((e) => PriceOptionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        reviews: (json['reviews'] as List<dynamic>? ?? const [])
            .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'nameRoom': nameRoom,
        if (typeRoom != null) 'typeRoom': typeRoom!.toJson(),
        if (status != null) 'status': status,
        if (hotel != null) 'hotel': hotel!.toJson(),
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (description != null) 'description': description,
        if (amenities != null) 'amenities': amenities,
      };
}
