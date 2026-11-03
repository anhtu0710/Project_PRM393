// lib/services/price_config_service.dart
// Bảng giá — đọc ghi bảng PriceConfig, TypeRoom, TypeBooking trong SQLite

import '../database/database_helper.dart';
import '../models/price_config_model.dart';
import '../models/room_model.dart';

class PriceConfigService {
  TypeBookingModel _typeBookingFromRow(Map<String, Object?> row) {
    return TypeBookingModel(
      typeBookingId: row['TypeBookingId'] as String,
      typeName: row['TypeName'] as String? ?? '',
      bookingCode: row['BookingCode'] as String? ?? '',
      durationHours: row['DurationHours'] as int?,
    );
  }

  Future<List<PriceConfigModel>> getAllPriceConfigs() async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT p.PriceConfigId, p.Price, t.TypeRoomId, t.TypeRoom, t.pricePerHour,
             b.TypeBookingId, b.TypeName, b.BookingCode, b.DurationHours
      FROM PriceConfig p
      LEFT JOIN TypeRoom t ON p.TypeRoomId = t.TypeRoomId
      LEFT JOIN TypeBooking b ON p.TypeBookingId = b.TypeBookingId
      ORDER BY p.PriceConfigId''');
    return rows
        .map((row) => PriceConfigModel(
              priceConfigId: row['PriceConfigId'] as int,
              price: (row['Price'] as num).toDouble(),
              typeRoom: row['TypeRoomId'] == null
                  ? null
                  : TypeRoomModel(
                      typeRoomId: row['TypeRoomId'] as String,
                      typeRoom: row['TypeRoom'] as String? ?? '',
                      pricePerHour: (row['pricePerHour'] as num?)?.toDouble(),
                    ),
              typeBooking:
                  row['TypeBookingId'] == null ? null : _typeBookingFromRow(row),
            ))
        .toList();
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

  Future<List<TypeBookingModel>> getTypeBookings() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query('TypeBooking');
    return rows.map(_typeBookingFromRow).toList();
  }

  /// Tạo gói combo mới (bảng TypeBooking)
  Future<TypeBookingModel> createTypeBooking(TypeBookingModel typeBooking) async {
    final db = await DatabaseHelper.database;
    final existed = await db.query('TypeBooking',
        where: 'TypeBookingId = ?', whereArgs: [typeBooking.typeBookingId]);
    if (existed.isNotEmpty) throw 'Gói combo ${typeBooking.bookingCode} đã tồn tại';

    await db.insert('TypeBooking', {
      'TypeBookingId': typeBooking.typeBookingId,
      'TypeName': typeBooking.typeName,
      'BookingCode': typeBooking.bookingCode,
      'DurationHours': typeBooking.durationHours,
    });
    return typeBooking;
  }

  Future<void> createPriceConfig(PriceConfigModel config) async {
    if (config.typeRoom == null || config.typeBooking == null) {
      throw 'Vui lòng chọn loại phòng và gói combo';
    }
    final db = await DatabaseHelper.database;
    await db.insert('PriceConfig', {
      'TypeRoomId': config.typeRoom!.typeRoomId,
      'TypeBookingId': config.typeBooking!.typeBookingId,
      'Price': config.price,
    });
  }

  Future<void> updatePriceConfig(int id, PriceConfigModel config) async {
    final db = await DatabaseHelper.database;
    final values = <String, Object?>{'Price': config.price};
    if (config.typeRoom != null) values['TypeRoomId'] = config.typeRoom!.typeRoomId;
    if (config.typeBooking != null) {
      values['TypeBookingId'] = config.typeBooking!.typeBookingId;
    }
    await db.update('PriceConfig', values,
        where: 'PriceConfigId = ?', whereArgs: [id]);
  }

  Future<void> deletePriceConfig(int id) async {
    final db = await DatabaseHelper.database;
    await db.delete('PriceConfig', where: 'PriceConfigId = ?', whereArgs: [id]);
  }
}
