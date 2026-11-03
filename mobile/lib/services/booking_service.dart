// lib/services/booking_service.dart
// Đặt phòng — đọc ghi bảng Booking trong SQLite.
// Luật giống hệt BookingController.java bên Spring Boot.

import '../config/app_config.dart';
import '../database/database_helper.dart';
import '../models/booking_model.dart';
import 'auth_service.dart';

class BookingService {
  /// Lấy câu báo lỗi tiếng Việt (service ném lỗi dạng String)
  static String errorMessage(Object e, String fallback) {
    if (e is String) return e;
    return fallback;
  }

  // Câu SELECT dùng chung: booking + phòng + khách sạn + người đặt + combo
  static const String _selectBooking = '''
    SELECT b.*, r.nameRoom, r.imageUrl AS roomImageUrl,
           h.name AS hotelName, h.address AS hotelAddress,
           u.full_name, u.phone, t.TypeName
    FROM Booking b
    LEFT JOIN Room r ON b.RoomId = r.RoomId
    LEFT JOIN Hotel h ON r.HotelId = h.HotelId
    LEFT JOIN [User] u ON b.UserId = u.UserId
    LEFT JOIN TypeBooking t ON b.TypeBookingId = t.TypeBookingId''';

  /// Đổi 1 dòng kết quả SELECT thành BookingModel
  BookingModel _bookingFromRow(Map<String, Object?> row) {
    return BookingModel(
      bookingId: row['BookingId'] as int,
      roomId: row['RoomId'] as String,
      userId: row['UserId'] as String,
      typeBookingId: row['TypeBookingId'] as String,
      checkIn: DateTime.parse(row['checkIn'] as String),
      checkOut: row['checkOut'] == null
          ? null
          : DateTime.parse(row['checkOut'] as String),
      totalPrice: (row['totalPrice'] as num?)?.toDouble(),
      status: row['Status'] as String?,
      voucherCode: row['voucherCode'] as String?,
      discountAmount: (row['discountAmount'] as num?)?.toDouble(),
      note: row['note'] as String?,
      roomName: row['nameRoom'] as String?,
      roomImageUrl: row['roomImageUrl'] as String?,
      hotelName: row['hotelName'] as String?,
      hotelAddress: row['hotelAddress'] as String?,
      typeBookingName: row['TypeName'] as String?,
      userFullName: row['full_name'] as String?,
      userPhone: row['phone'] as String?,
    );
  }

  /// Tạo booking mới. Giá, giờ ra, giảm giá đều tính lại ở đây.
  Future<BookingModel> createBooking(BookingModel booking) async {
    // 1. Người đặt là người đang đăng nhập
    final user = await AuthService().getCurrentUser();
    if (user == null) throw 'Vui lòng đăng nhập';

    // 2. Kiểm tra dữ liệu đầu vào
    if (booking.roomId.isEmpty) throw 'Thiếu thông tin phòng';
    if (booking.typeBookingId.isEmpty) throw 'Thiếu hình thức thuê';
    if (booking.checkIn.isBefore(DateTime.now())) {
      throw 'Giờ nhận phòng phải sau thời điểm hiện tại';
    }

    final db = await DatabaseHelper.database;
    final rooms = await db.query('Room', where: 'RoomId = ?', whereArgs: [booking.roomId]);
    if (rooms.isEmpty) throw 'Không tìm thấy phòng';
    final room = rooms.first;

    // Phòng đang dùng / đang dọn thì tạm khoá đặt
    final roomStatus = room['Status'] as String?;
    if (roomStatus != AppConfig.roomAvailable) {
      throw 'Phòng đang ${roomStatus?.toLowerCase() ?? 'bận'}, tạm thời khóa đặt phòng!';
    }

    final types = await db.query('TypeBooking',
        where: 'TypeBookingId = ?', whereArgs: [booking.typeBookingId]);
    if (types.isEmpty) throw 'Không tìm thấy hình thức thuê';
    final durationHours = types.first['DurationHours'] as int?;

    // 3. Giờ trả phòng = giờ nhận + số giờ của combo
    final checkIn = booking.checkIn;
    DateTime checkOut;
    if (durationHours != null) {
      checkOut = checkIn.add(Duration(hours: durationHours));
    } else if (booking.checkOut != null && booking.checkOut!.isAfter(checkIn)) {
      checkOut = booking.checkOut!;
    } else {
      throw 'Giờ trả phòng không hợp lệ';
    }

    // 4. Kiểm tra trùng lịch với các booking khác của phòng này
    final others = await db.query('Booking', where: 'RoomId = ?', whereArgs: [booking.roomId]);
    for (final other in others) {
      final status = other['Status'];
      // Booking đã huỷ / bị từ chối / đã xong thì không giữ phòng nữa
      if (status == AppConfig.bookingCancelled ||
          status == AppConfig.bookingRejected ||
          status == AppConfig.bookingCompleted) {
        continue;
      }
      final otherIn = DateTime.parse(other['checkIn'] as String);
      final otherOut = other['checkOut'] == null
          ? otherIn.add(const Duration(hours: 2))
          : DateTime.parse(other['checkOut'] as String);
      // Hai khoảng [checkIn, checkOut) và [otherIn, otherOut) giao nhau
      if (checkIn.isBefore(otherOut) && checkOut.isAfter(otherIn)) {
        throw 'Phòng đã có người đặt trong khung giờ này, vui lòng chọn giờ khác';
      }
    }

    // 5. Lấy giá từ bảng PriceConfig
    final prices = await db.query('PriceConfig',
        where: 'TypeRoomId = ? AND TypeBookingId = ?',
        whereArgs: [room['TypeRoomId'], booking.typeBookingId]);
    if (prices.isEmpty) throw 'Chưa có giá cho loại phòng và combo này';
    final price = (prices.first['Price'] as num).toDouble();

    // 6. Áp voucher (nếu có)
    double discount = 0;
    String? voucherCode;
    if (booking.voucherCode != null && booking.voucherCode!.trim().isNotEmpty) {
      final voucher = await checkVoucher(booking.voucherCode!, price);
      discount = voucher.calculateDiscount(price);
      voucherCode = voucher.code;
    }

    // 7. Lưu booking. Booking mới luôn chờ duyệt (PENDING)
    final id = await db.insert('Booking', {
      'RoomId': booking.roomId,
      'UserId': user.userId,
      'TypeBookingId': booking.typeBookingId,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'totalPrice': price - discount,
      'Status': AppConfig.bookingPending,
      'voucherCode': voucherCode,
      'discountAmount': discount,
      'note': booking.note,
    });
    return getBookingById(id);
  }

  /// Lấy danh sách booking theo userId
  Future<List<BookingModel>> getBookingsByUser(String userId) async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('$_selectBooking WHERE b.UserId = ?', [userId]);
    return rows.map(_bookingFromRow).toList();
  }

  /// Lấy tất cả booking (Staff / Admin)
  Future<List<BookingModel>> getAllBookings() async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery(_selectBooking);
    return rows.map(_bookingFromRow).toList();
  }

  /// Cập nhật trạng thái booking (Duyệt, Từ chối, Check-in, Check-out)
  Future<BookingModel> updateBookingStatus(int id, String status) async {
    final db = await DatabaseHelper.database;
    await db.update('Booking', {'Status': status},
        where: 'BookingId = ?', whereArgs: [id]);
    return getBookingById(id);
  }

  /// Lấy chi tiết 1 booking
  Future<BookingModel> getBookingById(int id) async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('$_selectBooking WHERE b.BookingId = ?', [id]);
    if (rows.isEmpty) throw 'Không tìm thấy booking';
    return _bookingFromRow(rows.first);
  }

  /// Khách huỷ booking: chỉ chủ booking, chỉ khi đang chờ duyệt hoặc đã xác nhận
  Future<BookingModel> cancelBooking(int id) async {
    final user = await AuthService().getCurrentUser();
    final booking = await getBookingById(id);

    if (user == null || booking.userId != user.userId) {
      throw 'Bạn không có quyền huỷ booking này';
    }
    if (booking.status != AppConfig.bookingPending &&
        booking.status != AppConfig.bookingConfirmed) {
      throw 'Chỉ huỷ được booking đang chờ duyệt hoặc đã xác nhận';
    }
    return updateBookingStatus(id, AppConfig.bookingCancelled);
  }

  /// Đổi 1 dòng bảng Voucher thành VoucherModel (loại dùng ở màn đặt phòng)
  VoucherModel _voucherFromRow(Map<String, Object?> row) {
    return VoucherModel(
      code: row['Code'] as String,
      label: row['Description'] as String? ?? '',
      discountPercent: (row['DiscountPercent'] as num?)?.toDouble() ?? 0,
      discountAmount: (row['DiscountAmount'] as num?)?.toDouble(),
      minOrderAmount: (row['MinOrderAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Danh sách voucher còn hạn
  Future<List<VoucherModel>> getVouchers() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query('Voucher');
    final now = DateTime.now();
    return rows
        .where((r) => DateTime.parse(r['ExpiryDate'] as String).isAfter(now))
        .map(_voucherFromRow)
        .toList();
  }

  /// Kiểm tra mã voucher với tổng tiền. Sai thì ném câu báo lỗi.
  Future<VoucherModel> checkVoucher(String code, double amount) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query('Voucher',
        where: 'Code = ?', whereArgs: [code.trim().toUpperCase()]);
    if (rows.isEmpty) throw 'Mã voucher không tồn tại';
    final row = rows.first;

    if (DateTime.parse(row['ExpiryDate'] as String).isBefore(DateTime.now())) {
      throw 'Mã voucher đã hết hạn';
    }
    final minOrder = (row['MinOrderAmount'] as num?)?.toDouble() ?? 0;
    if (amount < minOrder) {
      throw 'Đơn tối thiểu để dùng mã này là ${minOrder.toStringAsFixed(0)}đ';
    }
    return _voucherFromRow(row);
  }

  /// Bảng giá: map "TYPEROOM|TYPEBOOKING" -> giá
  Future<Map<String, double>> getPrices() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query('PriceConfig');
    final result = <String, double>{};
    for (final r in rows) {
      final typeRoomId = (r['TypeRoomId'] as String).toUpperCase();
      result['$typeRoomId|${r['TypeBookingId']}'] = (r['Price'] as num).toDouble();
    }
    return result;
  }
}
