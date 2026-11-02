-- =============================================================================
-- GenzCinema Hotel — COMBINED DATABASE SETUP SCRIPT (SQL Server)
-- =============================================================================

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'GenzCinemaHotel')
    CREATE DATABASE GenzCinemaHotel;
GO
USE GenzCinemaHotel;
GO

-- 1. Bảng Hotel
CREATE TABLE Hotel (
    HotelId VARCHAR(50) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    address NVARCHAR(MAX),
    countRoom INT DEFAULT 0,
    phone VARCHAR(20),
    imageUrl VARCHAR(MAX)
);

-- 2. Bảng Role (Phân quyền)
CREATE TABLE Role (
    RoleId VARCHAR(50) PRIMARY KEY,
    RoleName NVARCHAR(100) NOT NULL
);

-- 3. Bảng TypeRoom (Loại phòng)
CREATE TABLE TypeRoom (
    TypeRoomId VARCHAR(50) PRIMARY KEY,
    TypeRoom NVARCHAR(100) NOT NULL,
    pricePerHour DECIMAL(18,2) NULL
);

-- 4. Bảng TypeBooking (Loại hình thuê)
CREATE TABLE TypeBooking (
    TypeBookingId VARCHAR(50) PRIMARY KEY,
    TypeName NVARCHAR(100) NOT NULL,
    BookingCode VARCHAR(50) NOT NULL,
    DurationHours INT NULL
);

-- 5. Bảng User
CREATE TABLE [User] (
    UserId VARCHAR(50) PRIMARY KEY,
    full_name NVARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    password VARCHAR(255) NOT NULL,
    Image_cccd VARCHAR(MAX),
    RoleId VARCHAR(50),
    IsLocked BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (RoleId) REFERENCES Role(RoleId)
);

-- 6. Bảng Room
CREATE TABLE Room (
    RoomId VARCHAR(50) PRIMARY KEY,
    nameRoom NVARCHAR(100) NOT NULL,
    TypeRoomId VARCHAR(50),
    Status NVARCHAR(50),
    HotelId VARCHAR(50),
    imageUrl VARCHAR(MAX),
    FOREIGN KEY (TypeRoomId) REFERENCES TypeRoom(TypeRoomId),
    FOREIGN KEY (HotelId) REFERENCES Hotel(HotelId)
);

-- 7. Bảng PriceConfig
CREATE TABLE PriceConfig (
    PriceConfigId INT IDENTITY(1,1) PRIMARY KEY,
    TypeRoomId VARCHAR(50) NOT NULL,
    TypeBookingId VARCHAR(50) NOT NULL,
    Price DECIMAL(18, 2) NOT NULL,
    FOREIGN KEY (TypeRoomId) REFERENCES TypeRoom(TypeRoomId),
    FOREIGN KEY (TypeBookingId) REFERENCES TypeBooking(TypeBookingId)
);

-- 8. Bảng Booking
CREATE TABLE Booking (
    BookingId INT IDENTITY(1,1) PRIMARY KEY,
    RoomId VARCHAR(50) NOT NULL,
    UserId VARCHAR(50) NOT NULL,
    TypeBookingId VARCHAR(50) NOT NULL,
    checkIn DATETIME NOT NULL,
    checkOut DATETIME NULL,
    totalPrice DECIMAL(18, 2),
    Status NVARCHAR(50),
    voucherCode VARCHAR(50) NULL,
    discountAmount DECIMAL(18, 2) NULL DEFAULT 0.00,
    note NVARCHAR(MAX) NULL,
    FOREIGN KEY (RoomId) REFERENCES Room(RoomId),
    FOREIGN KEY (UserId) REFERENCES [User](UserId),
    FOREIGN KEY (TypeBookingId) REFERENCES TypeBooking(TypeBookingId)
);

-- 9. Bảng PasswordResetToken
CREATE TABLE PasswordResetToken (
    token        VARCHAR(255) PRIMARY KEY,
    expiryTime   DATETIME     NOT NULL,
    isUsed       BIT          NOT NULL DEFAULT 0,
    UserId       VARCHAR(50),
    FOREIGN KEY (UserId) REFERENCES [User](UserId)
);

-- 10. Bảng Voucher
CREATE TABLE Voucher (
    VoucherId       INT IDENTITY(1,1) PRIMARY KEY,
    Code            VARCHAR(50)    NOT NULL UNIQUE,
    Description     NVARCHAR(255)  NULL,
    DiscountPercent DECIMAL(5, 2)  NULL,
    DiscountAmount  DECIMAL(18, 2) NULL,
    MinOrderAmount  DECIMAL(18, 2) NOT NULL DEFAULT 0,
    ExpiryDate      DATETIME       NOT NULL
);

-- 11. Bảng Review
CREATE TABLE Review (
    ReviewId  INT IDENTITY(1,1) PRIMARY KEY,
    BookingId INT           NOT NULL UNIQUE,
    RoomId    VARCHAR(50)   NOT NULL,
    UserId    VARCHAR(50)   NOT NULL,
    Rating    INT           NOT NULL,
    Comment   NVARCHAR(MAX) NULL,
    CreatedAt DATETIME      NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (BookingId) REFERENCES Booking(BookingId),
    FOREIGN KEY (RoomId)    REFERENCES Room(RoomId),
    FOREIGN KEY (UserId)    REFERENCES [User](UserId)
);

-- 12. Bảng Notification
CREATE TABLE Notification (
    NotificationId INT IDENTITY(1,1) PRIMARY KEY,
    UserId    VARCHAR(50)   NOT NULL,
    BookingId INT           NULL,
    Title     NVARCHAR(255) NOT NULL,
    Message   NVARCHAR(MAX) NOT NULL,
    IsRead    BIT           NOT NULL DEFAULT 0,
    CreatedAt DATETIME      NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (UserId)    REFERENCES [User](UserId),
    FOREIGN KEY (BookingId) REFERENCES Booking(BookingId)
);
GO

-- =============================================================================
-- SEED DATA
-- =============================================================================

INSERT INTO Role VALUES('ADMIN', 'Administrator'),('STAFF', 'Staff'),('CUSTOMER', 'Customer');

INSERT INTO TypeRoom (TypeRoomId, TypeRoom, pricePerHour) VALUES
('QUEEN', N'Phòng Queen', 96000),
('KING',  N'Phòng King',  106000);

INSERT INTO TypeBooking (TypeBookingId, TypeName, BookingCode, DurationHours) VALUES
('TB_2H',    N'Combo 2h xem phim + đồ ăn',        'COMBO_2H',    2),
('TB_4H',    N'Combo 4h',                           'COMBO_4H',    4),
('TB_5H',    N'Combo 5h',                           'COMBO_5H',    5),
('TB_6H',    N'Combo 6h',                           'COMBO_6H',    6),
('TB_DAY',   N'Combo ngày 7h-12h (1 nước pha chế)', 'COMBO_DAY',   5),
('TB_NIGHT', N'Combo đêm 23h-7h (1 nước pha chế)',  'COMBO_NIGHT', 8);

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
('HN001', N'GenZ Cinema - Hà Đông',      N'Lk13 Ngõ 2 Nguyễn Văn Lộc, P. Mộ Lao, Hà Đông, Hà Nội',           4, '0866521881', NULL),
('HN002', N'GenZ Cinema - Đống Đa',      N'Số 3 Ngõ 180 P. Nguyễn Lương Bằng, Quang Trung, Đống Đa, Hà Nội',  4, '0325186385', NULL),
('HN003', N'GenZ Cinema - Hai Bà Trưng', N'130 P. Tân Khai, Vĩnh Hưng, Hai Bà Trưng, Hà Nội',                 4, '0989838603', NULL),
('HN004', N'GenZ Cinema - Thanh Xuân',   N'103 P. Hoàng Ngân, Nhân Chính, Thanh Xuân, Hà Nội',                 4, '0823983881', NULL),
('HN005', N'GenZ Cinema - Cầu Giấy',     N'24 P. Hoa Bằng, Yên Hoà, Cầu Giấy, Hà Nội',                        4, '0877155379', NULL),
('HN006', N'GenZ Cinema - Tây Hồ',       N'135 P. Nhật Chiêu, Nhật Tân, Tây Hồ, Hà Nội',                      4, '0838408881', NULL),
('HN007', N'GenZ Cinema - Quang Trung',  N'86-88 P. Nguyễn Lương Bằng, Quang Trung, Hà Nội',                   4, '0816018881', NULL),
('HN008', N'GenZ Cinema - Bắc Từ Liêm',  N'462 Đ. Hoàng Công Chất, Cầu Diễn, Bắc Từ Liêm, Hà Nội',           4, '0846298881', NULL),
('HN009', N'GenZ Cinema - Thanh Liệt',   N'06-N05 khu tái định cư xóm chùa, Triều Khúc, Thanh Liệt, Hà Nội',  4, '0823660705', NULL);

INSERT INTO Room (RoomId, nameRoom, TypeRoomId, Status, HotelId, imageUrl) VALUES
('HN001_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN001', NULL),
('HN001_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN001', NULL),
('HN001_K01', N'King 01',  'KING',  N'Trống', 'HN001', NULL),
('HN001_K02', N'King 02',  'KING',  N'Trống', 'HN001', NULL),
('HN002_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN002', NULL),
('HN002_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN002', NULL),
('HN002_K01', N'King 01',  'KING',  N'Trống', 'HN002', NULL),
('HN002_K02', N'King 02',  'KING',  N'Trống', 'HN002', NULL),
('HN003_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN003', NULL),
('HN003_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN003', NULL),
('HN003_K01', N'King 01',  'KING',  N'Trống', 'HN003', NULL),
('HN003_K02', N'King 02',  'KING',  N'Trống', 'HN003', NULL),
('HN004_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN004', NULL),
('HN004_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN004', NULL),
('HN004_K01', N'King 01',  'KING',  N'Trống', 'HN004', NULL),
('HN004_K02', N'King 02',  'KING',  N'Trống', 'HN004', NULL),
('HN005_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN005', NULL),
('HN005_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN005', NULL),
('HN005_K01', N'King 01',  'KING',  N'Trống', 'HN005', NULL),
('HN005_K02', N'King 02',  'KING',  N'Trống', 'HN005', NULL),
('HN006_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN006', NULL),
('HN006_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN006', NULL),
('HN006_K01', N'King 01',  'KING',  N'Trống', 'HN006', NULL),
('HN006_K02', N'King 02',  'KING',  N'Trống', 'HN006', NULL),
('HN007_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN007', NULL),
('HN007_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN007', NULL),
('HN007_K01', N'King 01',  'KING',  N'Trống', 'HN007', NULL),
('HN007_K02', N'King 02',  'KING',  N'Trống', 'HN007', NULL),
('HN008_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN008', NULL),
('HN008_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN008', NULL),
('HN008_K01', N'King 01',  'KING',  N'Trống', 'HN008', NULL),
('HN008_K02', N'King 02',  'KING',  N'Trống', 'HN008', NULL),
('HN009_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN009', NULL),
('HN009_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN009', NULL),
('HN009_K01', N'King 01',  'KING',  N'Trống', 'HN009', NULL),
('HN009_K02', N'King 02',  'KING',  N'Trống', 'HN009', NULL);

INSERT INTO [User] (UserId, full_name, phone, email, password, RoleId, IsLocked) VALUES
('SEED_ADMIN',    N'Admin Test', '0900000001', 'admin@genz.test',    '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'ADMIN',    0),
('SEED_STAFF',    N'Staff Test', '0900000002', 'staff@genz.test',    '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'STAFF',    0),
('SEED_CUSTOMER', N'Khách Test', '0900000003', 'customer@genz.test', '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'CUSTOMER', 0);

INSERT INTO Voucher (Code, Description, DiscountPercent, DiscountAmount, MinOrderAmount, ExpiryDate) VALUES
('GENZ10',  N'Giảm 10% mọi đơn',                         10,   NULL,  0,      '2027-12-31'),
('GIAM50K', N'Giảm 50.000đ cho đơn từ 250.000đ',         NULL, 50000, 250000, '2027-12-31'),
('HETHAN',  N'Voucher đã hết hạn, dùng để test báo lỗi', 20,   NULL,  0,      '2025-01-01');

INSERT INTO Booking (RoomId, UserId, TypeBookingId, checkIn, checkOut, totalPrice, Status, voucherCode, discountAmount, note) VALUES
('HN001_Q01', 'SEED_CUSTOMER', 'TB_2H',    '2026-11-01 19:00', '2026-11-01 21:00', 276000, 'COMPLETED', NULL,     0,     N'Dữ liệu mẫu'),
('HN001_K01', 'SEED_CUSTOMER', 'TB_4H',    '2026-10-31 18:00', '2026-10-31 22:00', 326000, 'COMPLETED', NULL,     0,     N'Dữ liệu mẫu'),
('HN002_Q01', 'SEED_CUSTOMER', 'TB_NIGHT', '2026-10-30 23:00', '2026-10-31 07:00', 296000, 'COMPLETED', NULL,     0,     N'Dữ liệu mẫu'),
('HN003_K02', 'SEED_CUSTOMER', 'TB_DAY',   '2026-10-28 07:00', '2026-10-28 12:00', 221400, 'COMPLETED', 'GENZ10', 24600, N'Dữ liệu mẫu'),
('HN005_Q02', 'SEED_CUSTOMER', 'TB_6H',    '2026-10-25 14:00', '2026-10-25 20:00', 416000, 'COMPLETED', NULL,     0,     N'Dữ liệu mẫu'),
('HN002_K01', 'SEED_CUSTOMER', 'TB_2H',    '2026-10-29 20:00', '2026-10-29 22:00', 286000, 'CANCELLED', NULL,     0,     N'Dữ liệu mẫu'),
('HN001_Q02', 'SEED_CUSTOMER', 'TB_2H',    '2026-11-05 19:00', '2026-11-05 21:00', 276000, 'PENDING',   NULL,     0,     N'Dữ liệu mẫu'),
('HN006_Q01', 'SEED_CUSTOMER', 'TB_5H',    '2026-11-05 14:00', '2026-11-05 19:00', 366000, 'PENDING',   NULL,     0,     N'Dữ liệu mẫu'),
('HN004_K01', 'SEED_CUSTOMER', 'TB_4H',    '2026-11-06 18:00', '2026-11-06 22:00', 326000, 'CONFIRMED', NULL,     0,     N'Dữ liệu mẫu');

INSERT INTO Review (BookingId, RoomId, UserId, Rating, Comment)
SELECT BookingId, RoomId, UserId, 5, N'Phòng sạch, màn chiếu nét, sẽ quay lại.'
FROM Booking
WHERE UserId = 'SEED_CUSTOMER' AND RoomId = 'HN001_Q01';

INSERT INTO Notification (UserId, BookingId, Title, Message)
SELECT UserId, BookingId, N'Đặt phòng đã được xác nhận', N'Staff đã xác nhận booking của bạn. Hẹn gặp bạn!'
FROM Booking
WHERE UserId = 'SEED_CUSTOMER' AND Status = 'CONFIRMED';
GO
