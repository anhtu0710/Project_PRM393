-- =============================================================================
-- GenzCinema Hotel — COMBINED DATABASE SETUP SCRIPT (PostgreSQL cho Aiven / Supabase)
-- Dán trực tiếp file này vào Query Editor của Aiven rồi bấm RUN / EXECUTE.
-- =============================================================================

-- 1. Bảng Hotel
CREATE TABLE IF NOT EXISTS Hotel (
    HotelId VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    countRoom INT DEFAULT 0,
    phone VARCHAR(20),
    imageUrl TEXT
);

-- 2. Bảng Role (Phân quyền)
CREATE TABLE IF NOT EXISTS Role (
    RoleId VARCHAR(50) PRIMARY KEY,
    RoleName VARCHAR(100) NOT NULL
);

-- 3. Bảng TypeRoom (Loại phòng)
CREATE TABLE IF NOT EXISTS TypeRoom (
    TypeRoomId VARCHAR(50) PRIMARY KEY,
    TypeRoom VARCHAR(100) NOT NULL,
    pricePerHour DECIMAL(18,2) NULL
);

-- 4. Bảng TypeBooking (Loại hình thuê)
CREATE TABLE IF NOT EXISTS TypeBooking (
    TypeBookingId VARCHAR(50) PRIMARY KEY,
    TypeName VARCHAR(100) NOT NULL,
    BookingCode VARCHAR(50) NOT NULL,
    DurationHours INT NULL
);

-- 5. Bảng User
CREATE TABLE IF NOT EXISTS "user" (
    UserId VARCHAR(50) PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    password VARCHAR(255) NOT NULL,
    Image_cccd TEXT,
    RoleId VARCHAR(50),
    IsLocked BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (RoleId) REFERENCES Role(RoleId)
);

-- 6. Bảng Room
CREATE TABLE IF NOT EXISTS Room (
    RoomId VARCHAR(50) PRIMARY KEY,
    nameRoom VARCHAR(100) NOT NULL,
    TypeRoomId VARCHAR(50),
    Status VARCHAR(50),
    HotelId VARCHAR(50),
    imageUrl TEXT,
    FOREIGN KEY (TypeRoomId) REFERENCES TypeRoom(TypeRoomId),
    FOREIGN KEY (HotelId) REFERENCES Hotel(HotelId)
);

-- 7. Bảng PriceConfig
CREATE TABLE IF NOT EXISTS PriceConfig (
    PriceConfigId SERIAL PRIMARY KEY,
    TypeRoomId VARCHAR(50) NOT NULL,
    TypeBookingId VARCHAR(50) NOT NULL,
    Price DECIMAL(18, 2) NOT NULL,
    FOREIGN KEY (TypeRoomId) REFERENCES TypeRoom(TypeRoomId),
    FOREIGN KEY (TypeBookingId) REFERENCES TypeBooking(TypeBookingId)
);

-- 8. Bảng Booking
CREATE TABLE IF NOT EXISTS Booking (
    BookingId SERIAL PRIMARY KEY,
    RoomId VARCHAR(50) NOT NULL,
    UserId VARCHAR(50) NOT NULL,
    TypeBookingId VARCHAR(50) NOT NULL,
    checkIn TIMESTAMP NOT NULL,
    checkOut TIMESTAMP NULL,
    totalPrice DECIMAL(18, 2),
    Status VARCHAR(50),
    voucherCode VARCHAR(50) NULL,
    discountAmount DECIMAL(18, 2) NULL DEFAULT 0.00,
    note TEXT NULL,
    FOREIGN KEY (RoomId) REFERENCES Room(RoomId),
    FOREIGN KEY (UserId) REFERENCES "user"(UserId),
    FOREIGN KEY (TypeBookingId) REFERENCES TypeBooking(TypeBookingId)
);

-- 9. Bảng PasswordResetToken
CREATE TABLE IF NOT EXISTS PasswordResetToken (
    token        VARCHAR(255) PRIMARY KEY,
    expiryTime   TIMESTAMP    NOT NULL,
    isUsed       BOOLEAN      NOT NULL DEFAULT FALSE,
    UserId       VARCHAR(50),
    FOREIGN KEY (UserId) REFERENCES "user"(UserId)
);

-- 10. Bảng Voucher
CREATE TABLE IF NOT EXISTS Voucher (
    VoucherId       SERIAL PRIMARY KEY,
    Code            VARCHAR(50)    NOT NULL UNIQUE,
    Description     VARCHAR(255)  NULL,
    DiscountPercent DECIMAL(5, 2)  NULL,
    DiscountAmount  DECIMAL(18, 2) NULL,
    MinOrderAmount  DECIMAL(18, 2) NOT NULL DEFAULT 0,
    ExpiryDate      TIMESTAMP      NOT NULL
);

-- 11. Bảng Review
CREATE TABLE IF NOT EXISTS Review (
    ReviewId  SERIAL PRIMARY KEY,
    BookingId INT           NOT NULL UNIQUE,
    RoomId    VARCHAR(50)   NOT NULL,
    UserId    VARCHAR(50)   NOT NULL,
    Rating    INT           NOT NULL,
    Comment   TEXT NULL,
    CreatedAt TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (BookingId) REFERENCES Booking(BookingId),
    FOREIGN KEY (RoomId)    REFERENCES Room(RoomId),
    FOREIGN KEY (UserId)    REFERENCES "user"(UserId)
);

-- 12. Bảng Notification
CREATE TABLE IF NOT EXISTS Notification (
    NotificationId SERIAL PRIMARY KEY,
    UserId    VARCHAR(50)   NOT NULL,
    BookingId INT           NULL,
    Title     VARCHAR(255) NOT NULL,
    Message   TEXT NOT NULL,
    IsRead    BOOLEAN       NOT NULL DEFAULT FALSE,
    CreatedAt TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserId)    REFERENCES "user"(UserId),
    FOREIGN KEY (BookingId) REFERENCES Booking(BookingId)
);

-- =============================================================================
-- SEED DATA
-- =============================================================================

INSERT INTO Role (RoleId, RoleName) VALUES
('ADMIN', 'Administrator'),
('STAFF', 'Staff'),
('CUSTOMER', 'Customer')
ON CONFLICT (RoleId) DO NOTHING;

INSERT INTO TypeRoom (TypeRoomId, TypeRoom, pricePerHour) VALUES
('QUEEN', 'Phòng Queen', 96000),
('KING',  'Phòng King',  106000)
ON CONFLICT (TypeRoomId) DO NOTHING;

INSERT INTO TypeBooking (TypeBookingId, TypeName, BookingCode, DurationHours) VALUES
('TB_2H',    'Combo 2h xem phim + đồ ăn',        'COMBO_2H',    2),
('TB_4H',    'Combo 4h',                           'COMBO_4H',    4),
('TB_5H',    'Combo 5h',                           'COMBO_5H',    5),
('TB_6H',    'Combo 6h',                           'COMBO_6H',    6),
('TB_DAY',   'Combo ngày 7h-12h (1 nước pha chế)', 'COMBO_DAY',   5),
('TB_NIGHT', 'Combo đêm 23h-7h (1 nước pha chế)',  'COMBO_NIGHT', 8)
ON CONFLICT (TypeBookingId) DO NOTHING;

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

INSERT INTO Hotel (HotelId, name, address, countRoom, phone, imageUrl) VALUES
('HN001', 'GenZ Cinema - Hà Đông',      'Lk13 Ngõ 2 Nguyễn Văn Lộc, P. Mộ Lao, Hà Đông, Hà Nội',           4, '0866521881', NULL),
('HN002', 'GenZ Cinema - Đống Đa',      'Số 3 Ngõ 180 P. Nguyễn Lương Bằng, Quang Trung, Đống Đa, Hà Nội',  4, '0325186385', NULL),
('HN003', 'GenZ Cinema - Hai Bà Trưng', '130 P. Tân Khai, Vĩnh Hưng, Hai Bà Trưng, Hà Nội',                 4, '0989838603', NULL),
('HN004', 'GenZ Cinema - Thanh Xuân',   '103 P. Hoàng Ngân, Nhân Chính, Thanh Xuân, Hà Nội',                 4, '0823983881', NULL),
('HN005', 'GenZ Cinema - Cầu Giấy',     '24 P. Hoa Bằng, Yên Hoà, Cầu Giấy, Hà Nội',                        4, '0877155379', NULL),
('HN006', 'GenZ Cinema - Tây Hồ',       '135 P. Nhật Chiêu, Nhật Tân, Tây Hồ, Hà Nội',                      4, '0838408881', NULL),
('HN007', 'GenZ Cinema - Quang Trung',  '86-88 P. Nguyễn Lương Bằng, Quang Trung, Hà Nội',                   4, '0816018881', NULL),
('HN008', 'GenZ Cinema - Bắc Từ Liêm',  '462 Đ. Hoàng Công Chất, Cầu Diễn, Bắc Từ Liêm, Hà Nội',           4, '0846298881', NULL),
('HN009', 'GenZ Cinema - Thanh Liệt',   '06-N05 khu tái định cư xóm chùa, Triều Khúc, Thanh Liệt, Hà Nội',  4, '0823660705', NULL)
ON CONFLICT (HotelId) DO NOTHING;

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
('HN009_K02', 'King 02',  'KING',  'Trống', 'HN009', NULL)
ON CONFLICT (RoomId) DO NOTHING;

INSERT INTO "user" (UserId, full_name, phone, email, password, RoleId, IsLocked) VALUES
('SEED_ADMIN',    'Admin Test', '0900000001', 'admin@genz.test',    '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'ADMIN',    FALSE),
('SEED_STAFF',    'Staff Test', '0900000002', 'staff@genz.test',    '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'STAFF',    FALSE),
('SEED_CUSTOMER', 'Khách Test', '0900000003', 'customer@genz.test', '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'CUSTOMER', FALSE)
ON CONFLICT (UserId) DO NOTHING;

INSERT INTO Voucher (Code, Description, DiscountPercent, DiscountAmount, MinOrderAmount, ExpiryDate) VALUES
('GENZ10',  'Giảm 10% mọi đơn',                         10,   NULL,  0,      '2027-12-31 23:59:59'),
('GIAM50K', 'Giảm 50.000đ cho đơn từ 250.000đ',         NULL, 50000, 250000, '2027-12-31 23:59:59'),
('HETHAN',  'Voucher đã hết hạn, dùng để test báo lỗi', 20,   NULL,  0,      '2025-01-01 00:00:00')
ON CONFLICT (Code) DO NOTHING;

INSERT INTO Booking (RoomId, UserId, TypeBookingId, checkIn, checkOut, totalPrice, Status, voucherCode, discountAmount, note) VALUES
('HN001_Q01', 'SEED_CUSTOMER', 'TB_2H',    '2026-11-01 19:00:00', '2026-11-01 21:00:00', 276000, 'COMPLETED', NULL,     0,     'Dữ liệu mẫu'),
('HN001_K01', 'SEED_CUSTOMER', 'TB_4H',    '2026-10-31 18:00:00', '2026-10-31 22:00:00', 326000, 'COMPLETED', NULL,     0,     'Dữ liệu mẫu'),
('HN002_Q01', 'SEED_CUSTOMER', 'TB_NIGHT', '2026-10-30 23:00:00', '2026-10-31 07:00:00', 296000, 'COMPLETED', NULL,     0,     'Dữ liệu mẫu'),
('HN003_K02', 'SEED_CUSTOMER', 'TB_DAY',   '2026-10-28 07:00:00', '2026-10-28 12:00:00', 221400, 'COMPLETED', 'GENZ10', 24600, 'Dữ liệu mẫu'),
('HN005_Q02', 'SEED_CUSTOMER', 'TB_6H',    '2026-10-25 14:00:00', '2026-10-25 20:00:00', 416000, 'COMPLETED', NULL,     0,     'Dữ liệu mẫu'),
('HN002_K01', 'SEED_CUSTOMER', 'TB_2H',    '2026-10-29 20:00:00', '2026-10-29 22:00:00', 286000, 'CANCELLED', NULL,     0,     'Dữ liệu mẫu'),
('HN001_Q02', 'SEED_CUSTOMER', 'TB_2H',    '2026-11-05 19:00:00', '2026-11-05 21:00:00', 276000, 'PENDING',   NULL,     0,     'Dữ liệu mẫu'),
('HN006_Q01', 'SEED_CUSTOMER', 'TB_5H',    '2026-11-05 14:00:00', '2026-11-05 19:00:00', 366000, 'PENDING',   NULL,     0,     'Dữ liệu mẫu'),
('HN004_K01', 'SEED_CUSTOMER', 'TB_4H',    '2026-11-06 18:00:00', '2026-11-06 22:00:00', 326000, 'CONFIRMED', NULL,     0,     'Dữ liệu mẫu');

INSERT INTO Review (BookingId, RoomId, UserId, Rating, Comment)
SELECT BookingId, RoomId, UserId, 5, 'Phòng sạch, màn chiếu nét, sẽ quay lại.'
FROM Booking
WHERE UserId = 'SEED_CUSTOMER' AND RoomId = 'HN001_Q01';

INSERT INTO Notification (UserId, BookingId, Title, Message)
SELECT UserId, BookingId, 'Đặt phòng đã được xác nhận', 'Staff đã xác nhận booking của bạn. Hẹn gặp bạn!'
FROM Booking
WHERE UserId = 'SEED_CUSTOMER' AND Status = 'CONFIRMED';
