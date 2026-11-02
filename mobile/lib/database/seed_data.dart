// lib/database/seed_data.dart
// Dữ liệu mẫu, chép từ SQLQuery1.sql + sprint_foundation.sql.
// Chỉ chạy 1 lần lúc app vừa cài (khi database chưa có).
//
// Tài khoản test (mật khẩu chung: Genz@123):
//   admin@genz.test    — ADMIN
//   staff@genz.test    — STAFF
//   customer@genz.test — CUSTOMER

import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

Future<void> insertSeedData(Database db) async {
  // ── Role ────────────────────────────────────────────────────────────────
  await db.execute('''
    INSERT INTO Role (RoleId, RoleName) VALUES
    ('ADMIN', 'Administrator'), ('STAFF', 'Staff'), ('CUSTOMER', 'Customer')''');

  // ── TypeRoom ────────────────────────────────────────────────────────────
  await db.execute('''
    INSERT INTO TypeRoom (TypeRoomId, TypeRoom, pricePerHour) VALUES
    ('QUEEN', 'Phòng Queen', 96000),
    ('KING',  'Phòng King',  106000)''');

  // ── TypeBooking ─────────────────────────────────────────────────────────
  await db.execute('''
    INSERT INTO TypeBooking (TypeBookingId, TypeName, BookingCode, DurationHours) VALUES
    ('TB_2H',    'Combo 2h xem phim + đồ ăn',        'COMBO_2H',    2),
    ('TB_4H',    'Combo 4h',                           'COMBO_4H',    4),
    ('TB_5H',    'Combo 5h',                           'COMBO_5H',    5),
    ('TB_6H',    'Combo 6h',                           'COMBO_6H',    6),
    ('TB_DAY',   'Combo ngày 7h-12h (1 nước pha chế)', 'COMBO_DAY',   5),
    ('TB_NIGHT', 'Combo đêm 23h-7h (1 nước pha chế)',  'COMBO_NIGHT', 8)''');

  // ── PriceConfig ─────────────────────────────────────────────────────────
  await db.execute('''
    INSERT INTO PriceConfig (TypeRoomId, TypeBookingId, Price) VALUES
    ('QUEEN', 'TB_2H',    276000),
    ('KING',  'TB_2H',    286000),
    ('QUEEN', 'TB_4H',    296000),
    ('KING',  'TB_4H',    326000),
    ('QUEEN', 'TB_5H',    366000),
    ('KING',  'TB_5H',    396000),
    ('QUEEN', 'TB_6H',    416000),
    ('KING',  'TB_6H',    446000),
    ('QUEEN', 'TB_DAY',   196000),
    ('KING',  'TB_DAY',   246000),
    ('QUEEN', 'TB_NIGHT', 296000),
    ('KING',  'TB_NIGHT', 336000)''');

  // ── Hotel (9 cơ sở thật) ────────────────────────────────────────────────
  await db.execute('''
    INSERT INTO Hotel (HotelId, name, address, countRoom, phone, imageUrl) VALUES
    ('HN001', 'GenZ Cinema - Hà Đông',      'Lk13 Ngõ 2 Nguyễn Văn Lộc, P. Mộ Lao, Hà Đông, Hà Nội',           4, '0866521881', NULL),
    ('HN002', 'GenZ Cinema - Đống Đa',      'Số 3 Ngõ 180 P. Nguyễn Lương Bằng, Quang Trung, Đống Đa, Hà Nội',  4, '0325186385', NULL),
    ('HN003', 'GenZ Cinema - Hai Bà Trưng', '130 P. Tân Khai, Vĩnh Hưng, Hai Bà Trưng, Hà Nội',                 4, '0989838603', NULL),
    ('HN004', 'GenZ Cinema - Thanh Xuân',   '103 P. Hoàng Ngân, Nhân Chính, Thanh Xuân, Hà Nội',                 4, '0823983881', NULL),
    ('HN005', 'GenZ Cinema - Cầu Giấy',     '24 P. Hoa Bằng, Yên Hoà, Cầu Giấy, Hà Nội',                        4, '0877155379', NULL),
    ('HN006', 'GenZ Cinema - Tây Hồ',       '135 P. Nhật Chiêu, Nhật Tân, Tây Hồ, Hà Nội',                      4, '0838408881', NULL),
    ('HN007', 'GenZ Cinema - Quang Trung',  '86-88 P. Nguyễn Lương Bằng, Quang Trung, Hà Nội',                   4, '0816018881', NULL),
    ('HN008', 'GenZ Cinema - Bắc Từ Liêm',  '462 Đ. Hoàng Công Chất, Cầu Diễn, Bắc Từ Liêm, Hà Nội',           4, '0846298881', NULL),
    ('HN009', 'GenZ Cinema - Thanh Liệt',   '06-N05 khu tái định cư xóm chùa, Triều Khúc, Thanh Liệt, Hà Nội',  4, '0823660705', NULL)''');

  // ── Room: mỗi cơ sở 2 Queen + 2 King ────────────────────────────────────
  for (int i = 1; i <= 9; i++) {
    final hotelId = 'HN00$i';
    await db.execute('''
      INSERT INTO Room (RoomId, nameRoom, TypeRoomId, Status, HotelId, imageUrl) VALUES
      ('${hotelId}_Q01', 'Queen 01', 'QUEEN', 'Trống', '$hotelId', NULL),
      ('${hotelId}_Q02', 'Queen 02', 'QUEEN', 'Trống', '$hotelId', NULL),
      ('${hotelId}_K01', 'King 01',  'KING',  'Trống', '$hotelId', NULL),
      ('${hotelId}_K02', 'King 02',  'KING',  'Trống', '$hotelId', NULL)''');
  }

  // ── Tài khoản test ──────────────────────────────────────────────────────
  final password = DatabaseHelper.hashPassword('Genz@123');
  await db.execute('''
    INSERT INTO [User] (UserId, full_name, phone, email, password, RoleId, IsLocked) VALUES
    ('SEED_ADMIN',    'Admin Test', '0900000001', 'admin@genz.test',    '$password', 'ADMIN',    0),
    ('SEED_STAFF',    'Staff Test', '0900000002', 'staff@genz.test',    '$password', 'STAFF',    0),
    ('SEED_CUSTOMER', 'Khách Test', '0900000003', 'customer@genz.test', '$password', 'CUSTOMER', 0)''');

  // ── Voucher mẫu ─────────────────────────────────────────────────────────
  await db.execute('''
    INSERT INTO Voucher (Code, Description, DiscountPercent, DiscountAmount, MinOrderAmount, ExpiryDate) VALUES
    ('GENZ10',  'Giảm 10% mọi đơn',                         10,   NULL,  0,      '2030-12-31T23:59:59.000'),
    ('GIAM50K', 'Giảm 50.000đ cho đơn từ 250.000đ',         NULL, 50000, 250000, '2030-12-31T23:59:59.000'),
    ('HETHAN',  'Voucher đã hết hạn, dùng để test báo lỗi', 20,   NULL,  0,      '2025-01-01T00:00:00.000')''');

  // ── Booking mẫu của customer@genz.test ──────────────────────────────────
  // Ngày tính theo HÔM NAY (lúc cài app), để dashboard lúc nào cũng có số liệu.
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Hàm nhỏ: thêm 1 booking, checkIn = hôm nay + days ngày, lúc hour giờ
  Future<void> addBooking(String roomId, String typeBookingId, int days,
      int hour, int hours, double price, String status,
      {String? voucherCode, double discount = 0}) async {
    final checkIn = today.add(Duration(days: days, hours: hour));
    final checkOut = checkIn.add(Duration(hours: hours));
    await db.insert('Booking', {
      'RoomId': roomId,
      'UserId': 'SEED_CUSTOMER',
      'TypeBookingId': typeBookingId,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'totalPrice': price,
      'Status': status,
      'voucherCode': voucherCode,
      'discountAmount': discount,
      'note': 'Dữ liệu mẫu',
    });
  }

  // Đã qua: dùng cho dashboard doanh thu và đánh giá
  await addBooking('HN001_Q01', 'TB_2H', -1, 19, 2, 276000, 'COMPLETED');
  await addBooking('HN001_K01', 'TB_4H', -2, 18, 4, 326000, 'COMPLETED');
  await addBooking('HN002_Q01', 'TB_NIGHT', -3, 23, 8, 296000, 'COMPLETED');
  await addBooking('HN003_K02', 'TB_DAY', -5, 7, 5, 221400, 'COMPLETED',
      voucherCode: 'GENZ10', discount: 24600);
  await addBooking('HN005_Q02', 'TB_6H', -8, 14, 6, 416000, 'COMPLETED');
  await addBooking('HN002_K01', 'TB_2H', -4, 20, 2, 286000, 'CANCELLED');
  // Sắp tới: dùng cho staff duyệt và check-in
  await addBooking('HN001_Q02', 'TB_2H', 3, 19, 2, 276000, 'PENDING');
  await addBooking('HN006_Q01', 'TB_5H', 3, 14, 5, 366000, 'PENDING');
  await addBooking('HN004_K01', 'TB_4H', 4, 18, 4, 326000, 'CONFIRMED');

  // ── Một đánh giá mẫu (booking đầu tiên, phòng HN001_Q01) ───────────────
  await db.execute('''
    INSERT INTO Review (BookingId, RoomId, UserId, Rating, Comment, CreatedAt)
    SELECT BookingId, RoomId, UserId, 5, 'Phòng sạch, màn chiếu nét, sẽ quay lại.', checkOut
    FROM Booking
    WHERE UserId = 'SEED_CUSTOMER' AND RoomId = 'HN001_Q01' ''');

  // ── Một thông báo mẫu (booking đã xác nhận) ─────────────────────────────
  await db.execute('''
    INSERT INTO Notification (UserId, BookingId, Title, Message, CreatedAt)
    SELECT UserId, BookingId, 'Đặt phòng đã được xác nhận',
           'Staff đã xác nhận booking của bạn. Hẹn gặp bạn!', '${now.toIso8601String()}'
    FROM Booking
    WHERE UserId = 'SEED_CUSTOMER' AND Status = 'CONFIRMED' ''');
}
