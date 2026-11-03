// lib/services/hotel_service.dart
// Chi nhánh (khách sạn) — đọc ghi bảng Hotel trong SQLite

import '../database/database_helper.dart';
import '../models/room_model.dart';

class HotelService {
  HotelModel _hotelFromRow(Map<String, Object?> row) {
    return HotelModel(
      hotelId: row['HotelId'] as String,
      name: row['name'] as String? ?? '',
      address: row['address'] as String? ?? '',
      phone: row['phone'] as String?,
      imageUrl: row['imageUrl'] as String?,
      countRoom: row['countRoom'] as int?,
      city: row['City'] as String?,
    );
  }

  Future<List<HotelModel>> getAllHotels() async {
    final db = await DatabaseHelper.database;
    // countRoom đếm số phòng thật đang có của chi nhánh
    final rows = await db.rawQuery('''
      SELECT h.HotelId, h.name, h.address, h.phone, h.imageUrl, h.City,
             (SELECT COUNT(*) FROM Room r WHERE r.HotelId = h.HotelId) AS countRoom
      FROM Hotel h
      ORDER BY h.HotelId''');
    return rows.map(_hotelFromRow).toList();
  }

  Future<HotelModel> createHotel(HotelModel hotel) async {
    if (hotel.hotelId.trim().isEmpty) throw 'Vui lòng nhập mã chi nhánh';
    final db = await DatabaseHelper.database;
    final existed =
        await db.query('Hotel', where: 'HotelId = ?', whereArgs: [hotel.hotelId]);
    if (existed.isNotEmpty) throw 'Mã chi nhánh ${hotel.hotelId} đã tồn tại';

    await db.insert('Hotel', {
      'HotelId': hotel.hotelId.trim(),
      'name': hotel.name,
      'address': hotel.address,
      'phone': hotel.phone,
      'imageUrl': hotel.imageUrl,
      'countRoom': 0,
      'City': hotel.city,
    });
    return hotel;
  }

  Future<HotelModel> updateHotel(String id, HotelModel hotel) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'Hotel',
      {
        'name': hotel.name,
        'address': hotel.address,
        'phone': hotel.phone,
        'imageUrl': hotel.imageUrl,
        // Form sửa chi nhánh chưa có ô thành phố: để trống thì giữ giá trị cũ
        if (hotel.city != null) 'City': hotel.city,
      },
      where: 'HotelId = ?',
      whereArgs: [id],
    );
    return hotel;
  }

  /// Xoá chi nhánh + toàn bộ phòng của nó.
  /// Chặn nếu có phòng còn booking đang chờ / đã xác nhận / đang ở.
  Future<void> deleteHotel(String id) async {
    final db = await DatabaseHelper.database;
    final rooms = await db.query('Room', where: 'HotelId = ?', whereArgs: [id]);

    // 1. Kiểm tra booking đang hoạt động
    for (final room in rooms) {
      final active = await db.query('Booking',
          where: "RoomId = ? AND Status IN ('PENDING', 'CONFIRMED', 'CHECKED_IN')",
          whereArgs: [room['RoomId']]);
      if (active.isNotEmpty) {
        throw 'Không thể xóa chi nhánh vì phòng ${room['nameRoom']} (${room['RoomId']}) '
            'đang có ${active.length} booking đang hoạt động!';
      }
    }

    // 2. Xoá dữ liệu của từng phòng, rồi xoá phòng
    for (final room in rooms) {
      final roomId = room['RoomId'];
      await db.rawDelete(
          'DELETE FROM Notification WHERE BookingId IN (SELECT BookingId FROM Booking WHERE RoomId = ?)',
          [roomId]);
      await db.delete('Review', where: 'RoomId = ?', whereArgs: [roomId]);
      await db.delete('Booking', where: 'RoomId = ?', whereArgs: [roomId]);
      await db.delete('Room', where: 'RoomId = ?', whereArgs: [roomId]);
    }

    // 3. Xoá chi nhánh
    await db.delete('Hotel', where: 'HotelId = ?', whereArgs: [id]);
  }
}
