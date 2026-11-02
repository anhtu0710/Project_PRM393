// lib/services/room_service.dart
// Phòng — đọc ghi bảng Room trong SQLite (JOIN thêm Hotel, TypeRoom để hiển thị)

import '../database/database_helper.dart';
import '../models/room_model.dart';

class RoomService {
  // Câu SELECT dùng chung: phòng + khách sạn + loại phòng
  static const String _selectRoom = '''
    SELECT r.*, h.name AS hotelName, h.address, h.phone, h.countRoom,
           h.imageUrl AS hotelImageUrl, t.TypeRoom, t.pricePerHour
    FROM Room r
    LEFT JOIN Hotel h ON r.HotelId = h.HotelId
    LEFT JOIN TypeRoom t ON r.TypeRoomId = t.TypeRoomId''';

  /// Đổi 1 dòng kết quả SELECT thành RoomModel
  RoomModel _roomFromRow(Map<String, Object?> row,
      {double averageRating = 0,
      int reviewCount = 0,
      List<PriceOptionModel> priceOptions = const [],
      List<ReviewModel> reviews = const []}) {
    return RoomModel(
      roomId: row['RoomId'] as String,
      nameRoom: row['nameRoom'] as String? ?? '',
      status: row['Status'] as String?,
      imageUrl: row['imageUrl'] as String?,
      typeRoom: row['TypeRoomId'] == null
          ? null
          : TypeRoomModel(
              typeRoomId: row['TypeRoomId'] as String,
              typeRoom: row['TypeRoom'] as String? ?? '',
              pricePerHour: (row['pricePerHour'] as num?)?.toDouble(),
            ),
      hotel: row['HotelId'] == null
          ? null
          : HotelModel(
              hotelId: row['HotelId'] as String,
              name: row['hotelName'] as String? ?? '',
              address: row['address'] as String? ?? '',
              phone: row['phone'] as String?,
              imageUrl: row['hotelImageUrl'] as String?,
              countRoom: row['countRoom'] as int?,
            ),
      averageRating: averageRating,
      reviewCount: reviewCount,
      priceOptions: priceOptions,
      reviews: reviews,
    );
  }

  /// Danh sách phòng (có lọc). Lọc theo giờ: bỏ phòng đã có người đặt trùng giờ.
  Future<List<RoomModel>> getAllRooms({
    String? keyword,
    String? hotelId,
    String? typeRoomId,
    double? minPrice,
    double? maxPrice,
    DateTime? checkIn,
    DateTime? checkOut,
  }) async {
    if ((checkIn == null) != (checkOut == null)) {
      throw 'Vui lòng chọn cả giờ nhận và giờ trả phòng';
    }
    if (checkIn != null && !checkOut!.isAfter(checkIn)) {
      throw 'Giờ trả phòng phải sau giờ nhận phòng';
    }

    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('$_selectRoom ORDER BY r.RoomId');

    // Điểm đánh giá trung bình + số đánh giá của từng phòng
    final ratingRows = await db.rawQuery(
        'SELECT RoomId, AVG(Rating) AS avgRating, COUNT(*) AS total FROM Review GROUP BY RoomId');
    final ratings = <String, Map<String, Object?>>{};
    for (final r in ratingRows) {
      ratings[r['RoomId'] as String] = r;
    }

    final result = <RoomModel>[];
    for (final row in rows) {
      final room = _roomFromRow(
        row,
        averageRating: _round1(ratings[row['RoomId']]?['avgRating'] as num?),
        reviewCount: ratings[row['RoomId']]?['total'] as int? ?? 0,
      );

      // Lọc từng điều kiện (điều kiện nào null thì bỏ qua)
      if (hotelId != null && room.hotel?.hotelId != hotelId) continue;
      if (typeRoomId != null && room.typeRoom?.typeRoomId != typeRoomId) continue;
      final price = room.typeRoom?.pricePerHour ?? 0;
      if (minPrice != null && price < minPrice) continue;
      if (maxPrice != null && price > maxPrice) continue;
      if (keyword != null && keyword.trim().isNotEmpty) {
        final k = keyword.trim().toLowerCase();
        final text = '${room.nameRoom} ${room.typeRoom?.typeRoom} '
                '${room.hotel?.name} ${room.hotel?.address}'
            .toLowerCase();
        if (!text.contains(k)) continue;
      }
      if (checkIn != null &&
          await _isBusy(room.roomId, checkIn, checkOut!)) {
        continue;
      }
      result.add(room);
    }
    return result;
  }

  /// Phòng có booking còn hiệu lực trùng khoảng [checkIn, checkOut) không
  Future<bool> _isBusy(String roomId, DateTime checkIn, DateTime checkOut) async {
    final db = await DatabaseHelper.database;
    final bookings = await db.query('Booking',
        where: "RoomId = ? AND Status IN ('PENDING', 'CONFIRMED', 'CHECKED_IN')",
        whereArgs: [roomId]);
    for (final b in bookings) {
      final otherIn = DateTime.parse(b['checkIn'] as String);
      final otherOut = b['checkOut'] == null
          ? otherIn.add(const Duration(hours: 2))
          : DateTime.parse(b['checkOut'] as String);
      if (checkIn.isBefore(otherOut) && checkOut.isAfter(otherIn)) return true;
    }
    return false;
  }

  /// Chi tiết 1 phòng: kèm bảng giá và danh sách đánh giá
  Future<RoomModel> getRoomById(String id) async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('$_selectRoom WHERE r.RoomId = ?', [id]);
    if (rows.isEmpty) throw 'Không tìm thấy phòng';
    final row = rows.first;

    // Bảng giá của loại phòng này
    final priceRows = await db.rawQuery('''
      SELECT p.Price, b.* FROM PriceConfig p
      JOIN TypeBooking b ON p.TypeBookingId = b.TypeBookingId
      WHERE p.TypeRoomId = ?
      ORDER BY b.DurationHours''', [row['TypeRoomId']]);
    final priceOptions = priceRows
        .map((p) => PriceOptionModel(
              typeBookingId: p['TypeBookingId'] as String,
              typeName: p['TypeName'] as String? ?? '',
              bookingCode: p['BookingCode'] as String? ?? '',
              durationHours: p['DurationHours'] as int?,
              price: (p['Price'] as num).toDouble(),
            ))
        .toList();

    // Đánh giá của phòng, mới nhất lên đầu
    final reviewRows = await db.rawQuery('''
      SELECT rv.*, u.full_name FROM Review rv
      LEFT JOIN [User] u ON rv.UserId = u.UserId
      WHERE rv.RoomId = ?
      ORDER BY rv.CreatedAt DESC''', [id]);
    final reviews = reviewRows
        .map((r) => ReviewModel(
              reviewId: r['ReviewId'] as int,
              bookingId: r['BookingId'] as int,
              rating: r['Rating'] as int,
              comment: r['Comment'] as String?,
              reviewerName: r['full_name'] as String? ?? 'Khách hàng',
              createdAt: DateTime.tryParse(r['CreatedAt'] as String? ?? ''),
            ))
        .toList();

    double total = 0;
    for (final r in reviews) {
      total += r.rating;
    }
    final average = reviews.isEmpty ? 0.0 : _round1(total / reviews.length);

    return _roomFromRow(row,
        averageRating: average,
        reviewCount: reviews.length,
        priceOptions: priceOptions,
        reviews: reviews);
  }

  Future<List<RoomModel>> getAvailableRooms() async {
    final rooms = await getAllRooms();
    return rooms.where((r) => r.status == 'Trống').toList();
  }

  Future<RoomModel> createRoom(RoomModel room) async {
    if (room.roomId.trim().isEmpty) throw 'Vui lòng nhập mã phòng';
    final db = await DatabaseHelper.database;
    final existed = await db.query('Room', where: 'RoomId = ?', whereArgs: [room.roomId]);
    if (existed.isNotEmpty) throw 'Mã phòng ${room.roomId} đã tồn tại';

    await db.insert('Room', {
      'RoomId': room.roomId.trim(),
      'nameRoom': room.nameRoom,
      'TypeRoomId': room.typeRoom?.typeRoomId,
      'Status': room.status ?? 'Trống',
      'HotelId': room.hotel?.hotelId,
      'imageUrl': room.imageUrl,
    });
    return getRoomById(room.roomId.trim());
  }

  Future<RoomModel> updateRoom(String id, RoomModel room) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'Room',
      {
        'nameRoom': room.nameRoom,
        'TypeRoomId': room.typeRoom?.typeRoomId,
        'Status': room.status,
        'HotelId': room.hotel?.hotelId,
        'imageUrl': room.imageUrl,
      },
      where: 'RoomId = ?',
      whereArgs: [id],
    );
    return getRoomById(id);
  }

  /// Xoá phòng. Chặn nếu phòng còn booking đang chờ / đã xác nhận / đang ở.
  Future<void> deleteRoom(String id) async {
    final db = await DatabaseHelper.database;
    final active = await db.query('Booking',
        where: "RoomId = ? AND Status IN ('PENDING', 'CONFIRMED', 'CHECKED_IN')",
        whereArgs: [id]);
    if (active.isNotEmpty) {
      throw 'Không thể xóa phòng vì đang có ${active.length} booking đang hoạt động!';
    }
    // Xoá dữ liệu cũ của phòng trước, rồi mới xoá phòng
    await db.delete('Review', where: 'RoomId = ?', whereArgs: [id]);
    await db.delete('Booking', where: 'RoomId = ?', whereArgs: [id]);
    await db.delete('Room', where: 'RoomId = ?', whereArgs: [id]);
  }

  Future<List<TypeRoomModel>> getTypeRooms() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query('TypeRoom');
    return rows
        .map((r) => TypeRoomModel(
              typeRoomId: r['TypeRoomId'] as String,
              typeRoom: r['TypeRoom'] as String? ?? '',
              pricePerHour: (r['pricePerHour'] as num?)?.toDouble(),
            ))
        .toList();
  }

  /// Làm tròn 1 chữ số thập phân (4.666 -> 4.7)
  double _round1(num? value) {
    if (value == null) return 0;
    return (value * 10).round() / 10;
  }
}
