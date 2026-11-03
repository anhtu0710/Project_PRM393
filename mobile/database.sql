-- =============================================================================
-- GenzCinema Hotel — Database SQLite (gộp SQLQuery1.sql + sprint_foundation.sql)
--
-- App tự chạy file này 1 LẦN khi mới cài (xem lib/database/database_helper.dart).
-- Sửa file này xong phải GỠ APP rồi cài lại thì mới chạy lại từ đầu.
--
-- Khác SQL Server:
--   NVARCHAR / VARCHAR -> TEXT,  DECIMAL -> REAL,  BIT -> INTEGER (0 / 1)
--   DATETIME -> TEXT dạng '2026-11-05T19:00:00'
--   IDENTITY(1,1) -> INTEGER PRIMARY KEY AUTOINCREMENT
--   Không có N'...', không có GO, không có USE
--
-- Tài khoản test (mật khẩu chung: Genz@123, lưu dạng mã hoá SHA-256):
--   admin@genz.test    — ADMIN
--   staff@genz.test    — STAFF
--   customer@genz.test — CUSTOMER
--
-- Lưu ý: không viết dấu chấm phẩy trong chú thích hay trong dữ liệu,
-- vì app tách từng câu lệnh theo dấu chấm phẩy.
-- =============================================================================


-- =============================================================================
-- 1. TẠO BẢNG
-- =============================================================================

-- Role (phân quyền)
CREATE TABLE Role (
    RoleId   TEXT PRIMARY KEY,
    RoleName TEXT NOT NULL
);

-- TypeRoom (loại phòng)
CREATE TABLE TypeRoom (
    TypeRoomId   TEXT PRIMARY KEY,
    TypeRoom     TEXT NOT NULL,         -- tên loại phòng, VD: Phòng Queen
    pricePerHour REAL
);

-- TypeBooking (gói combo / hình thức thuê)
CREATE TABLE TypeBooking (
    TypeBookingId TEXT PRIMARY KEY,
    TypeName      TEXT NOT NULL,
    BookingCode   TEXT NOT NULL,
    DurationHours INTEGER               -- số giờ của gói
);

-- User (người dùng). IsLocked: 0 = bình thường, 1 = bị khoá
CREATE TABLE [User] (
    UserId    TEXT PRIMARY KEY,
    full_name TEXT NOT NULL,
    phone     TEXT,
    email     TEXT,
    password  TEXT NOT NULL,
    RoleId    TEXT REFERENCES Role(RoleId),
    IsLocked  INTEGER NOT NULL DEFAULT 0
);

-- Hotel (chi nhánh)
CREATE TABLE Hotel (
    HotelId   TEXT PRIMARY KEY,
    name      TEXT NOT NULL,
    address   TEXT,
    countRoom INTEGER DEFAULT 0,
    phone     TEXT,
    imageUrl  TEXT
);

-- Room (phòng). Status: Trống, Đang dùng, Đang dọn
CREATE TABLE Room (
    RoomId     TEXT PRIMARY KEY,
    nameRoom   TEXT NOT NULL,
    TypeRoomId TEXT REFERENCES TypeRoom(TypeRoomId),
    Status     TEXT,
    HotelId    TEXT REFERENCES Hotel(HotelId),
    imageUrl   TEXT
);

-- PriceConfig (giá của 1 loại phòng theo 1 gói combo)
CREATE TABLE PriceConfig (
    PriceConfigId INTEGER PRIMARY KEY AUTOINCREMENT,
    TypeRoomId    TEXT NOT NULL REFERENCES TypeRoom(TypeRoomId),
    TypeBookingId TEXT NOT NULL REFERENCES TypeBooking(TypeBookingId),
    Price         REAL NOT NULL
);

-- Booking (đặt phòng)
-- Status: PENDING, CONFIRMED, REJECTED, CHECKED_IN, COMPLETED, CANCELLED
CREATE TABLE Booking (
    BookingId      INTEGER PRIMARY KEY AUTOINCREMENT,
    RoomId         TEXT NOT NULL REFERENCES Room(RoomId),
    UserId         TEXT NOT NULL REFERENCES [User](UserId),
    TypeBookingId  TEXT NOT NULL REFERENCES TypeBooking(TypeBookingId),
    checkIn        TEXT NOT NULL,
    checkOut       TEXT,
    totalPrice     REAL,
    Status         TEXT,
    voucherCode    TEXT,
    discountAmount REAL DEFAULT 0,
    note           TEXT
);

-- PasswordResetToken (mã đặt lại mật khẩu, hết hạn sau 15 phút)
CREATE TABLE PasswordResetToken (
    token      TEXT PRIMARY KEY,
    expiryTime TEXT NOT NULL,
    isUsed     INTEGER NOT NULL DEFAULT 0,
    UserId     TEXT REFERENCES [User](UserId)
);

-- Voucher: chỉ điền 1 trong 2 cột giảm giá (% hoặc số tiền)
CREATE TABLE Voucher (
    VoucherId       INTEGER PRIMARY KEY AUTOINCREMENT,
    Code            TEXT NOT NULL UNIQUE,
    Description     TEXT,
    DiscountPercent REAL,               -- VD: 10 = giảm 10%
    DiscountAmount  REAL,               -- VD: 50000 = giảm 50.000đ
    MinOrderAmount  REAL NOT NULL DEFAULT 0,
    ExpiryDate      TEXT NOT NULL
);

-- Review: mỗi booking chỉ đánh giá 1 lần (BookingId UNIQUE)
CREATE TABLE Review (
    ReviewId  INTEGER PRIMARY KEY AUTOINCREMENT,
    BookingId INTEGER NOT NULL UNIQUE REFERENCES Booking(BookingId),
    RoomId    TEXT NOT NULL REFERENCES Room(RoomId),
    UserId    TEXT NOT NULL REFERENCES [User](UserId),
    Rating    INTEGER NOT NULL,         -- 1 đến 5 sao
    Comment   TEXT,
    CreatedAt TEXT NOT NULL
);

-- Notification: thông báo gửi cho 1 người dùng
CREATE TABLE Notification (
    NotificationId INTEGER PRIMARY KEY AUTOINCREMENT,
    UserId    TEXT NOT NULL REFERENCES [User](UserId),
    BookingId INTEGER REFERENCES Booking(BookingId),
    Title     TEXT NOT NULL,
    Message   TEXT NOT NULL,
    IsRead    INTEGER NOT NULL DEFAULT 0,   -- 0 = chưa đọc
    CreatedAt TEXT NOT NULL
);


-- =============================================================================
-- 2. DỮ LIỆU MẪU
-- =============================================================================

INSERT INTO Role (RoleId, RoleName) VALUES
('ADMIN',    'Administrator'),
('STAFF',    'Staff'),
('CUSTOMER', 'Customer');

INSERT INTO TypeRoom (TypeRoomId, TypeRoom, pricePerHour) VALUES
('QUEEN', 'Phòng Queen', 96000),
('KING',  'Phòng King',  106000);

INSERT INTO TypeBooking (TypeBookingId, TypeName, BookingCode, DurationHours) VALUES
('TB_2H',    'Combo 2h xem phim + đồ ăn',        'COMBO_2H',    2),
('TB_4H',    'Combo 4h',                           'COMBO_4H',    4),
('TB_5H',    'Combo 5h',                           'COMBO_5H',    5),
('TB_6H',    'Combo 6h',                           'COMBO_6H',    6),
('TB_DAY',   'Combo ngày 7h-12h (1 nước pha chế)', 'COMBO_DAY',   5),
('TB_NIGHT', 'Combo đêm 23h-7h (1 nước pha chế)',  'COMBO_NIGHT', 8);

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
('KING',  'TB_NIGHT', 336000);

-- 9 cơ sở thật
INSERT INTO Hotel (HotelId, name, address, countRoom, phone, imageUrl) VALUES
('HN001', 'GenZ Cinema - Hà Đông',      'Lk13 Ngõ 2 Nguyễn Văn Lộc, P. Mộ Lao, Hà Đông, Hà Nội',           4, '0866521881', NULL),
('HN002', 'GenZ Cinema - Đống Đa',      'Số 3 Ngõ 180 P. Nguyễn Lương Bằng, Quang Trung, Đống Đa, Hà Nội',  4, '0325186385', NULL),
('HN003', 'GenZ Cinema - Hai Bà Trưng', '130 P. Tân Khai, Vĩnh Hưng, Hai Bà Trưng, Hà Nội',                 4, '0989838603', NULL),
('HN004', 'GenZ Cinema - Thanh Xuân',   '103 P. Hoàng Ngân, Nhân Chính, Thanh Xuân, Hà Nội',                 4, '0823983881', NULL),
('HN005', 'GenZ Cinema - Cầu Giấy',     '24 P. Hoa Bằng, Yên Hoà, Cầu Giấy, Hà Nội',                        4, '0877155379', NULL),
('HN006', 'GenZ Cinema - Tây Hồ',       '135 P. Nhật Chiêu, Nhật Tân, Tây Hồ, Hà Nội',                      4, '0838408881', NULL),
('HN007', 'GenZ Cinema - Quang Trung',  '86-88 P. Nguyễn Lương Bằng, Quang Trung, Hà Nội',                   4, '0816018881', NULL),
('HN008', 'GenZ Cinema - Bắc Từ Liêm',  '462 Đ. Hoàng Công Chất, Cầu Diễn, Bắc Từ Liêm, Hà Nội',           4, '0846298881', NULL),
('HN009', 'GenZ Cinema - Thanh Liệt',   '06-N05 khu tái định cư xóm chùa, Triều Khúc, Thanh Liệt, Hà Nội',  4, '0823660705', NULL);

-- Mỗi cơ sở 2 Queen + 2 King
INSERT INTO Room (RoomId, nameRoom, TypeRoomId, Status, HotelId, imageUrl) VALUES
('HN001_Q01', 'Queen 01', 'QUEEN', 'Trống', 'HN001', NULL),
('HN001_Q02', 'Queen 02', 'QUEEN', 'Trống', 'HN001', NULL),
('HN001_K01', 'King 01',  'KING',  'Trống', 'HN001', NULL),
('HN001_K02', 'King 02',  'KING',  'Trống', 'HN001', NULL),
('HN002_Q01', 'Queen 01', 'QUEEN', 'Trống', 'HN002', NULL),
('HN002_Q02', 'Queen 02', 'QUEEN', 'Trống', 'HN002', NULL),
('HN002_K01', 'King 01',  'KING',  'Trống', 'HN002', NULL),
('HN002_K02', 'King 02',  'KING',  'Trống', 'HN002', NULL),
('HN003_Q01', 'Queen 01', 'QUEEN', 'Trống', 'HN003', NULL),
('HN003_Q02', 'Queen 02', 'QUEEN', 'Trống', 'HN003', NULL),
('HN003_K01', 'King 01',  'KING',  'Trống', 'HN003', NULL),
('HN003_K02', 'King 02',  'KING',  'Trống', 'HN003', NULL),
('HN004_Q01', 'Queen 01', 'QUEEN', 'Trống', 'HN004', NULL),
('HN004_Q02', 'Queen 02', 'QUEEN', 'Trống', 'HN004', NULL),
('HN004_K01', 'King 01',  'KING',  'Trống', 'HN004', NULL),
('HN004_K02', 'King 02',  'KING',  'Trống', 'HN004', NULL),
('HN005_Q01', 'Queen 01', 'QUEEN', 'Trống', 'HN005', NULL),
('HN005_Q02', 'Queen 02', 'QUEEN', 'Trống', 'HN005', NULL),
('HN005_K01', 'King 01',  'KING',  'Trống', 'HN005', NULL),
('HN005_K02', 'King 02',  'KING',  'Trống', 'HN005', NULL),
('HN006_Q01', 'Queen 01', 'QUEEN', 'Trống', 'HN006', NULL),
('HN006_Q02', 'Queen 02', 'QUEEN', 'Trống', 'HN006', NULL),
('HN006_K01', 'King 01',  'KING',  'Trống', 'HN006', NULL),
('HN006_K02', 'King 02',  'KING',  'Trống', 'HN006', NULL),
('HN007_Q01', 'Queen 01', 'QUEEN', 'Trống', 'HN007', NULL),
('HN007_Q02', 'Queen 02', 'QUEEN', 'Trống', 'HN007', NULL),
('HN007_K01', 'King 01',  'KING',  'Trống', 'HN007', NULL),
('HN007_K02', 'King 02',  'KING',  'Trống', 'HN007', NULL),
('HN008_Q01', 'Queen 01', 'QUEEN', 'Trống', 'HN008', NULL),
('HN008_Q02', 'Queen 02', 'QUEEN', 'Trống', 'HN008', NULL),
('HN008_K01', 'King 01',  'KING',  'Trống', 'HN008', NULL),
('HN008_K02', 'King 02',  'KING',  'Trống', 'HN008', NULL),
('HN009_Q01', 'Queen 01', 'QUEEN', 'Trống', 'HN009', NULL),
('HN009_Q02', 'Queen 02', 'QUEEN', 'Trống', 'HN009', NULL),
('HN009_K01', 'King 01',  'KING',  'Trống', 'HN009', NULL),
('HN009_K02', 'King 02',  'KING',  'Trống', 'HN009', NULL);

-- 3 tài khoản test. Mật khẩu Genz@123 đã mã hoá SHA-256
INSERT INTO [User] (UserId, full_name, phone, email, password, RoleId, IsLocked) VALUES
('SEED_ADMIN',    'Admin Test', '0900000001', 'admin@genz.test',    'd9ad71eecdd48cde2d276610b6f22b4313adb241348443b355788811afde020e', 'ADMIN',    0),
('SEED_STAFF',    'Staff Test', '0900000002', 'staff@genz.test',    'd9ad71eecdd48cde2d276610b6f22b4313adb241348443b355788811afde020e', 'STAFF',    0),
('SEED_CUSTOMER', 'Khách Test', '0900000003', 'customer@genz.test', 'd9ad71eecdd48cde2d276610b6f22b4313adb241348443b355788811afde020e', 'CUSTOMER', 0);

-- Voucher mẫu (HETHAN dùng để test báo lỗi hết hạn)
INSERT INTO Voucher (Code, Description, DiscountPercent, DiscountAmount, MinOrderAmount, ExpiryDate) VALUES
('GENZ10',  'Giảm 10% mọi đơn',                         10,   NULL,  0,      '2030-12-31T23:59:59'),
('GIAM50K', 'Giảm 50.000đ cho đơn từ 250.000đ',         NULL, 50000, 250000, '2030-12-31T23:59:59'),
('HETHAN',  'Voucher đã hết hạn, dùng để test báo lỗi', 20,   NULL,  0,      '2025-01-01T00:00:00');

-- Booking mẫu của customer@genz.test (giá lấy đúng từ bảng PriceConfig).
-- Ngày tính theo HÔM NAY lúc cài app, để dashboard lúc nào cũng có số liệu.
-- VD: strftime(..., 'now', 'localtime', 'start of day', '-1 day', '+19 hours')
--     = hôm qua lúc 19:00
INSERT INTO Booking (RoomId, UserId, TypeBookingId, checkIn, checkOut, totalPrice, Status, voucherCode, discountAmount, note) VALUES
-- Đã qua: dùng cho dashboard doanh thu và đánh giá
('HN001_Q01', 'SEED_CUSTOMER', 'TB_2H',
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '-1 day', '+19 hours'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '-1 day', '+21 hours'),
    276000, 'COMPLETED', NULL, 0, 'Dữ liệu mẫu'),
('HN001_K01', 'SEED_CUSTOMER', 'TB_4H',
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '-2 days', '+18 hours'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '-2 days', '+22 hours'),
    326000, 'COMPLETED', NULL, 0, 'Dữ liệu mẫu'),
('HN002_Q01', 'SEED_CUSTOMER', 'TB_NIGHT',
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '-3 days', '+23 hours'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '-2 days', '+7 hours'),
    296000, 'COMPLETED', NULL, 0, 'Dữ liệu mẫu'),
('HN003_K02', 'SEED_CUSTOMER', 'TB_DAY',
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '-5 days', '+7 hours'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '-5 days', '+12 hours'),
    221400, 'COMPLETED', 'GENZ10', 24600, 'Dữ liệu mẫu'),
('HN005_Q02', 'SEED_CUSTOMER', 'TB_6H',
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '-8 days', '+14 hours'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '-8 days', '+20 hours'),
    416000, 'COMPLETED', NULL, 0, 'Dữ liệu mẫu'),
('HN002_K01', 'SEED_CUSTOMER', 'TB_2H',
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '-4 days', '+20 hours'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '-4 days', '+22 hours'),
    286000, 'CANCELLED', NULL, 0, 'Dữ liệu mẫu'),
-- Sắp tới: dùng cho staff duyệt và check-in
('HN001_Q02', 'SEED_CUSTOMER', 'TB_2H',
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '+3 days', '+19 hours'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '+3 days', '+21 hours'),
    276000, 'PENDING', NULL, 0, 'Dữ liệu mẫu'),
('HN006_Q01', 'SEED_CUSTOMER', 'TB_5H',
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '+3 days', '+14 hours'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '+3 days', '+19 hours'),
    366000, 'PENDING', NULL, 0, 'Dữ liệu mẫu'),
('HN004_K01', 'SEED_CUSTOMER', 'TB_4H',
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '+4 days', '+18 hours'),
    strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime', 'start of day', '+4 days', '+22 hours'),
    326000, 'CONFIRMED', NULL, 0, 'Dữ liệu mẫu');

-- Một đánh giá mẫu (cho booking phòng HN001_Q01 ở trên)
INSERT INTO Review (BookingId, RoomId, UserId, Rating, Comment, CreatedAt)
SELECT BookingId, RoomId, UserId, 5, 'Phòng sạch, màn chiếu nét, sẽ quay lại.', checkOut
FROM Booking
WHERE UserId = 'SEED_CUSTOMER' AND RoomId = 'HN001_Q01';

-- Một thông báo mẫu (cho booking đã được xác nhận ở trên)
INSERT INTO Notification (UserId, BookingId, Title, Message, CreatedAt)
SELECT UserId, BookingId, 'Đặt phòng đã được xác nhận', 'Staff đã xác nhận booking của bạn. Hẹn gặp bạn!',
       strftime('%Y-%m-%dT%H:%M:%S', 'now', 'localtime')
FROM Booking
WHERE UserId = 'SEED_CUSTOMER' AND Status = 'CONFIRMED';
