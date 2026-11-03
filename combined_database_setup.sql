-- =============================================================================
-- GenzCinema Hotel — COMBINED DATABASE SETUP SCRIPT (SQL Server)
-- =============================================================================

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'GenzCinemaHotel')
    CREATE DATABASE GenzCinemaHotel;
GO
USE GenzCinemaHotel;
GO

-- 0. Xóa các bảng cũ nếu đã tồn tại (theo đúng thứ tự khóa ngoại)
IF OBJECT_ID('dbo.Notification', 'U') IS NOT NULL DROP TABLE dbo.Notification;
IF OBJECT_ID('dbo.Review', 'U') IS NOT NULL DROP TABLE dbo.Review;
IF OBJECT_ID('dbo.Booking', 'U') IS NOT NULL DROP TABLE dbo.Booking;
IF OBJECT_ID('dbo.PasswordResetToken', 'U') IS NOT NULL DROP TABLE dbo.PasswordResetToken;
IF OBJECT_ID('dbo.PriceConfig', 'U') IS NOT NULL DROP TABLE dbo.PriceConfig;
IF OBJECT_ID('dbo.Room', 'U') IS NOT NULL DROP TABLE dbo.Room;
IF OBJECT_ID('dbo.FoodMenu', 'U') IS NOT NULL DROP TABLE dbo.FoodMenu;
IF OBJECT_ID('dbo.Movie', 'U') IS NOT NULL DROP TABLE dbo.Movie;
IF OBJECT_ID('dbo.Voucher', 'U') IS NOT NULL DROP TABLE dbo.Voucher;
IF OBJECT_ID('dbo.TypeBooking', 'U') IS NOT NULL DROP TABLE dbo.TypeBooking;
IF OBJECT_ID('dbo.TypeRoom', 'U') IS NOT NULL DROP TABLE dbo.TypeRoom;
IF OBJECT_ID('dbo.Hotel', 'U') IS NOT NULL DROP TABLE dbo.Hotel;
IF OBJECT_ID('dbo.[User]', 'U') IS NOT NULL DROP TABLE dbo.[User];
IF OBJECT_ID('dbo.Role', 'U') IS NOT NULL DROP TABLE dbo.Role;
GO

-- 1. Bảng Hotel
CREATE TABLE Hotel (
    HotelId VARCHAR(50) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    address NVARCHAR(MAX),
    countRoom INT DEFAULT 0,
    phone VARCHAR(20),
    imageUrl VARCHAR(MAX),
    City NVARCHAR(100) NULL
);

-- 2. Bảng Role (Phân quyền)
CREATE TABLE Role (
    RoleId VARCHAR(50) PRIMARY KEY,
    RoleName NVARCHAR(100) NOT NULL
);

-- 3. Bảng TypeRoom (Loại phòng / Box chủ đề)
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

-- 5. Bảng User (Có cột HotelId gán Chi nhánh cho Staff)
CREATE TABLE [User] (
    UserId VARCHAR(50) PRIMARY KEY,
    full_name NVARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    password VARCHAR(255) NOT NULL,
    Image_cccd VARCHAR(MAX),
    RoleId VARCHAR(50),
    HotelId VARCHAR(50) NULL,
    IsLocked BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (RoleId) REFERENCES Role(RoleId),
    FOREIGN KEY (HotelId) REFERENCES Hotel(HotelId)
);

-- 6. Bảng Room
CREATE TABLE Room (
    RoomId VARCHAR(50) PRIMARY KEY,
    nameRoom NVARCHAR(100) NOT NULL,
    TypeRoomId VARCHAR(50),
    Status NVARCHAR(50),
    HotelId VARCHAR(50),
    imageUrl VARCHAR(MAX),
    description NVARCHAR(MAX) NULL,
    amenities NVARCHAR(MAX) NULL,
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

-- 13. Bảng FoodMenu (Thực đơn F&B đồ ăn thức uống)
CREATE TABLE FoodMenu (
    FoodId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(255) NOT NULL,
    Category NVARCHAR(100) NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    ImageUrl VARCHAR(MAX) NULL,
    Description NVARCHAR(MAX) NULL,
    IsAvailable BIT NOT NULL DEFAULT 1
);

-- 14. Bảng Movie (Danh sách Phim Hot đề cử)
CREATE TABLE Movie (
    MovieId INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(255) NOT NULL,
    Category NVARCHAR(100) NOT NULL,
    Rating DECIMAL(3,1) NOT NULL DEFAULT 5.0,
    Quality NVARCHAR(50) NOT NULL DEFAULT '4K Netflix',
    PosterUrl VARCHAR(MAX) NULL,
    Description NVARCHAR(MAX) NULL,
    IsHot BIT NOT NULL DEFAULT 1
);
GO

-- =============================================================================
-- SEED DATA CHUẨN ĐÚNG YÊU CẦU GENZCINEMA
-- =============================================================================

INSERT INTO Role VALUES('ADMIN', 'Administrator'),('STAFF', 'Staff'),('CUSTOMER', 'Customer');

-- Tất cả các Loại phòng Box chủ đề
INSERT INTO TypeRoom (TypeRoomId, TypeRoom, pricePerHour) VALUES
('QUEEN',    N'Phòng Queen',   96000),
('KING',     N'Phòng King',    106000),
('FOOTBALL', N'Football Box',  106000),
('GAMING',   N'Gaming Box',    106000),
('HOIAN',    N'Hội An Box',    96000),
('HONGKONG', N'HongKong Box',  96000),
('MARVEL',   N'Marvel Box',    96000),
('NATRA',    N'Natra Box',     96000),
('SAMURAI',  N'Samurai Box',   96000),
('ANIME',    N'Anime Box',     96000),
('AQUAMAN',  N'Aquaman Box',   96000),
('AVATAR',   N'Avatar Box',    96000),
('AVENGER',  N'Avenger Box',   96000),
('SAKURA',   N'Sakura Box',    96000),
('TEDDY',    N'Teddy Box',     96000);

-- Các gói thuê
INSERT INTO TypeBooking (TypeBookingId, TypeName, BookingCode, DurationHours) VALUES
('TB_HOURLY', N'Thuê theo giờ',                    'HOURLY',      1),
('TB_2H',     N'Combo 2h xem phim + đồ ăn',        'COMBO_2H',    2),
('TB_4H',     N'Combo 4h xem phim + đồ ăn',        'COMBO_4H',    4),
('TB_5H',     N'Combo 5h giải trí',                'COMBO_5H',    5),
('TB_6H',     N'Combo 6h giải trí',                'COMBO_6H',    6),
('TB_DAY',    N'Combo ngày 7h-12h (1 nước pha chế)', 'COMBO_DAY',   5),
('TB_NIGHT',  N'Combo đêm 23h-7h (1 nước pha chế)',  'COMBO_NIGHT', 8);

-- Bảng giá PriceConfig cho tất cả các loại phòng
INSERT INTO PriceConfig (TypeRoomId, TypeBookingId, Price) VALUES
('QUEEN',    'TB_HOURLY', 96000),  ('QUEEN',    'TB_2H', 276000), ('QUEEN',    'TB_4H', 296000), ('QUEEN',    'TB_DAY', 196000), ('QUEEN',    'TB_NIGHT', 296000),
('KING',     'TB_HOURLY', 106000), ('KING',     'TB_2H', 286000), ('KING',     'TB_4H', 326000), ('KING',     'TB_DAY', 246000), ('KING',     'TB_NIGHT', 336000),
('FOOTBALL', 'TB_HOURLY', 106000), ('FOOTBALL', 'TB_2H', 286000), ('FOOTBALL', 'TB_4H', 326000), ('FOOTBALL', 'TB_DAY', 246000), ('FOOTBALL', 'TB_NIGHT', 336000),
('GAMING',   'TB_HOURLY', 106000), ('GAMING',   'TB_2H', 286000), ('GAMING',   'TB_4H', 326000), ('GAMING',   'TB_DAY', 246000), ('GAMING',   'TB_NIGHT', 336000),
('HOIAN',    'TB_HOURLY', 96000),  ('HOIAN',    'TB_2H', 276000), ('HOIAN',    'TB_4H', 296000), ('HOIAN',    'TB_DAY', 196000), ('HOIAN',    'TB_NIGHT', 296000),
('HONGKONG', 'TB_HOURLY', 96000),  ('HONGKONG', 'TB_2H', 276000), ('HONGKONG', 'TB_4H', 296000), ('HONGKONG', 'TB_DAY', 196000), ('HONGKONG', 'TB_NIGHT', 296000),
('MARVEL',   'TB_HOURLY', 96000),  ('MARVEL',   'TB_2H', 276000), ('MARVEL',   'TB_4H', 296000), ('MARVEL',   'TB_DAY', 196000), ('MARVEL',   'TB_NIGHT', 296000),
('NATRA',    'TB_HOURLY', 96000),  ('NATRA',    'TB_2H', 276000), ('NATRA',    'TB_4H', 296000), ('NATRA',    'TB_DAY', 196000), ('NATRA',    'TB_NIGHT', 296000),
('SAMURAI',  'TB_HOURLY', 96000),  ('SAMURAI',  'TB_2H', 276000), ('SAMURAI',  'TB_4H', 296000), ('SAMURAI',  'TB_DAY', 196000), ('SAMURAI',  'TB_NIGHT', 296000),
('ANIME',    'TB_HOURLY', 96000),  ('ANIME',    'TB_2H', 276000), ('ANIME',    'TB_4H', 296000), ('ANIME',    'TB_DAY', 196000), ('ANIME',    'TB_NIGHT', 296000),
('AQUAMAN',  'TB_HOURLY', 96000),  ('AQUAMAN',  'TB_2H', 276000), ('AQUAMAN',  'TB_4H', 296000), ('AQUAMAN',  'TB_DAY', 196000), ('AQUAMAN',  'TB_NIGHT', 296000),
('AVATAR',   'TB_HOURLY', 96000),  ('AVATAR',   'TB_2H', 276000), ('AVATAR',   'TB_4H', 296000), ('AVATAR',   'TB_DAY', 196000), ('AVATAR',   'TB_NIGHT', 296000),
('AVENGER',  'TB_HOURLY', 96000),  ('AVENGER',  'TB_2H', 276000), ('AVENGER',  'TB_4H', 296000), ('AVENGER',  'TB_DAY', 196000), ('AVENGER',  'TB_NIGHT', 296000),
('SAKURA',   'TB_HOURLY', 96000),  ('SAKURA',   'TB_2H', 276000), ('SAKURA',   'TB_4H', 296000), ('SAKURA',   'TB_DAY', 196000), ('SAKURA',   'TB_NIGHT', 296000),
('TEDDY',    'TB_HOURLY', 96000),  ('TEDDY',    'TB_2H', 276000), ('TEDDY',    'TB_4H', 296000), ('TEDDY',    'TB_DAY', 196000), ('TEDDY',    'TB_NIGHT', 296000);

-- Danh sách 9 Chi nhánh với URL Hình Ảnh chuẩn
INSERT INTO Hotel (HotelId, name, address, countRoom, phone, imageUrl, City) VALUES
('HN001', N'GenZ Cinema - Nguyễn Văn Lộc',   N'Số 13, Ngõ 2 Nguyễn Văn Lộc, P. Mộ Lao, Hà Đông, Hà Nội',          4, '0876583333', 'https://genzcinema.vn/wp-content/uploads/2024/01/hadong.jpg', N'Hà Nội'),
('HN002', N'GenZ Cinema - Hoa Bằng',        N'Số 24 P. Hoa Bằng, Yên Hoà, Cầu Giấy, Hà Nội',                     7, '0877155379', 'https://genzcinema.vn/wp-content/uploads/2024/01/caugiay.jpg', N'Hà Nội'),
('HN003', N'GenZ Cinema - Nguyễn Lương Bằng', N'Số 3, Ngõ 180 Nguyễn Lương Bằng, Quang Trung, Đống Đa, Hà Nội',    4, '0325186385', 'https://genzcinema.vn/wp-content/uploads/2024/01/dongda.jpg', N'Hà Nội'),
('HN004', N'GenZ Cinema - Hoàng Ngân',       N'Số 103 P. Hoàng Ngân, Nhân Chính, Thanh Xuân, Hà Nội',             4, '0823983881', 'https://genzcinema.vn/wp-content/uploads/2024/01/thanhxuan.jpg', N'Hà Nội'),
('HN005', N'GenZ Cinema - Lĩnh Nam',         N'Số 130 P. Lĩnh Nam, Vĩnh Hưng, Hoàng Mai, Hà Nội',                 4, '0989838603', 'https://genzcinema.vn/wp-content/uploads/2024/01/linhnam.jpg', N'Hà Nội'),
('HN006', N'GenZ Cinema - Hồ Tây',           N'Số 135 P. Nhật Chiêu, Nhật Tân, Tây Hồ, Hà Nội',                  4, '0838408881', 'https://genzcinema.vn/wp-content/uploads/2024/01/tayho.jpg', N'Hà Nội'),
('BN001', N'GenZ Cinema - Lý Đạo Thành',     N'Số 63 P. Lý Đạo Thành, TP. Bắc Ninh',                             4, '0876583333', 'https://genzcinema.vn/wp-content/uploads/2024/01/bacninh.jpg', N'Bắc Ninh'),
('HCM001', N'GenZ Cinema - Nguyễn Thái Bình',N'Số 419 Nguyễn Thái Bình, P. 12, Q. Tân Bình, TP. Hồ Chí Minh',     9, '0876583333', 'https://genzcinema.vn/wp-content/uploads/2024/01/tanbinh.jpg', N'TP. Hồ Chí Minh'),
('HCM002', N'GenZ Cinema - Âu Cơ',          N'Số 547 Âu Cơ, P. Phú Trung, Q. Tân Phú, TP. Hồ Chí Minh',          4, '0876583333', 'https://genzcinema.vn/wp-content/uploads/2024/01/tanphu.jpg', N'TP. Hồ Chí Minh');

-- Danh sách Phòng đúng chuẩn phân bổ yêu cầu với URL Hình Ảnh yêu cầu
INSERT INTO Room (RoomId, nameRoom, TypeRoomId, Status, HotelId, imageUrl, description, amenities) VALUES
-- 1. Cơ sở HN001 (Nguyễn Văn Lộc): 2 Queen, 2 King
('HN001_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRGcHios9GsQ4LKiKRGqJ9cwW645mYEOwWEqDxNUTYwRB88RsKZz-BjMwU&s=10', N'Phòng Queen chiếu phim riêng tư ấm cúng.', N'Máy chiếu 4K, Sofa bed, Điều hòa 2 chiều, Netflix 4K'),
('HN001_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', N'Phòng Queen xem phim không gian thoáng mát.', N'Máy chiếu 4K, Sofa bed, Máy lọc không khí, Netflix 4K'),
('HN001_K01', N'King 01',  'KING',  N'Trống', 'HN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  N'Phòng King cao cấp trang bị PC đôi chơi game.', N'Máy chiếu 4K, PC Couple RTX, Sofa đôi, Netflix 4K'),
('HN001_K02', N'King 02',  'KING',  N'Đang dùng', 'HN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  N'Phòng King rạp chiếu phim kết hợp dàn máy gaming.', N'Máy chiếu 4K, PC Couple RTX, Sofa đôi, Board game'),

-- 2. Cơ sở HN002 (Hoa Bằng - Hà Nội): 7 Box chủ đề
('HN002_FB', N'Football Box - Hoa Bằng', 'FOOTBALL', N'Trống', 'HN002', 'https://genzcinema.vn/wp-content/uploads/2025/06/IMG_5405-768x576.jpg', N'Không gian điện ảnh kết hợp giải trí thể thao sôi động.', N'Máy chiếu 4K, Sofa bed, Soundbar 5.1, Netflix 4K'),
('HN002_GM', N'Gaming Box - Hoa Bằng',   'GAMING',   N'Trống', 'HN002', 'https://genzcinema.vn/wp-content/uploads/2025/06/IMG_5399-768x576.jpg',   N'Màn chiếu rộng kết hợp giàn PC đôi chơi game cực mượt.', N'Máy chiếu 4K, PC Couple RTX, Sofa đôi, Netflix 4K'),
('HN002_HA', N'Hội An Box - Hoa Bằng',   'HOIAN',    N'Trống', 'HN002', 'https://genzcinema.vn/wp-content/uploads/2025/06/7-768x576.jpg',    N'Không gian phố cổ Hội An lãng mạn hoài niệm.', N'Máy chiếu 4K, Sofa bed, Đèn lồng trang trí, Netflix 4K'),
('HN002_HK', N'HongKong Box - Hoa Bằng', 'HONGKONG', N'Trống', 'HN002', 'https://genzcinema.vn/wp-content/uploads/2025/06/1-1024x768.png', N'Bầu không khí phố đêm Hongkong Neon cực chất.', N'Máy chiếu 4K, Sofa bed, Netflix 4K, Board game'),
('HN002_MV', N'Marvel Box - Hoa Bằng',   'MARVEL',   N'Đang dùng', 'HN002', 'https://genzcinema.vn/wp-content/uploads/2025/06/8-768x576.png',  N'Phong cách Siêu anh hùng Marvel cá tính.', N'Máy chiếu 4K, Sofa bed, Âm thanh surround, Netflix 4K'),
('HN002_NT', N'Natra Box - Hoa Bằng',    'NATRA',    N'Trống', 'HN002', 'https://genzcinema.vn/wp-content/uploads/2025/06/6-768x576.png',    N'Không gian huyền thoại Natra Ma Đồng Giáng Thế.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN002_SR', N'Samurai Box - Hoa Bằng',  'SAMURAI',  N'Trống', 'HN002', 'https://genzcinema.vn/wp-content/uploads/2025/06/3-1-768x576.png',  N'Phong cách võ sĩ Samurai Nhật Bản ấn tượng.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),

-- 3. Cơ sở HN003 (Nguyễn Lương Bằng): 2 Queen, 2 King
('HN003_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN003', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRGcHios9GsQ4LKiKRGqJ9cwW645mYEOwWEqDxNUTYwRB88RsKZz-BjMwU&s=10', N'Phòng Queen riêng tư.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN003_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN003', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRGcHios9GsQ4LKiKRGqJ9cwW645mYEOwWEqDxNUTYwRB88RsKZz-BjMwU&s=10', N'Phòng Queen ngọt ngào.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN003_K01', N'King 01',  'KING',  N'Trống', 'HN003', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  N'Phòng King có PC đôi.', N'Máy chiếu 4K, PC Couple, Netflix 4K'),
('HN003_K02', N'King 02',  'KING',  N'Trống', 'HN003', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  N'Phòng King rộng rãi.', N'Máy chiếu 4K, PC Couple, Netflix 4K'),

-- 4. Cơ sở HN004 (Hoàng Ngân): 2 Queen, 2 King
('HN004_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN004', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRGcHios9GsQ4LKiKRGqJ9cwW645mYEOwWEqDxNUTYwRB88RsKZz-BjMwU&s=10', N'Phòng Queen riêng tư.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN004_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN004', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRGcHios9GsQ4LKiKRGqJ9cwW645mYEOwWEqDxNUTYwRB88RsKZz-BjMwU&s=10', N'Phòng Queen hiện đại.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN004_K01', N'King 01',  'KING',  N'Đang dọn', 'HN004', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  N'Phòng King sang trọng.', N'Máy chiếu 4K, PC Couple, Netflix 4K'),
('HN004_K02', N'King 02',  'KING',  N'Trống', 'HN004', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  N'Phòng King đầy đủ tiện nghi.', N'Máy chiếu 4K, PC Couple, Netflix 4K'),

-- 5. Cơ sở HN005 (Lĩnh Nam): 2 Queen, 2 King
('HN005_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN005', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRGcHios9GsQ4LKiKRGqJ9cwW645mYEOwWEqDxNUTYwRB88RsKZz-BjMwU&s=10', N'Phòng Queen Lĩnh Nam.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN005_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN005', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRGcHios9GsQ4LKiKRGqJ9cwW645mYEOwWEqDxNUTYwRB88RsKZz-BjMwU&s=10', N'Phòng Queen thư giãn.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN005_K01', N'King 01',  'KING',  N'Trống', 'HN005', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  N'Phòng King PC đôi Lĩnh Nam.', N'Máy chiếu 4K, PC Couple, Netflix 4K'),
('HN005_K02', N'King 02',  'KING',  N'Trống', 'HN005', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  N'Phòng King cao cấp Lĩnh Nam.', N'Máy chiếu 4K, PC Couple, Netflix 4K'),

-- 6. Cơ sở HN006 (Hồ Tây): 2 Queen, 2 King
('HN006_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HN006', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRGcHios9GsQ4LKiKRGqJ9cwW645mYEOwWEqDxNUTYwRB88RsKZz-BjMwU&s=10', N'Phòng Queen view Hồ Tây.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN006_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HN006', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRGcHios9GsQ4LKiKRGqJ9cwW645mYEOwWEqDxNUTYwRB88RsKZz-BjMwU&s=10', N'Phòng Queen lãng mạn Hồ Tây.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN006_K01', N'King 01',  'KING',  N'Đang dùng', 'HN006', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  N'Phòng King Hồ Tây với PC đôi.', N'Máy chiếu 4K, PC Couple, Netflix 4K'),
('HN006_K02', N'King 02',  'KING',  N'Trống', 'HN006', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  N'Phòng King sang trọng Hồ Tây.', N'Máy chiếu 4K, PC Couple, Netflix 4K'),

-- 7. Cơ sở BN001 (Lý Đạo Thành - Bắc Ninh): 2 Queen, 2 King
('BN001_Q01', N'Queen 01', 'QUEEN', N'Trống', 'BN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRGcHios9GsQ4LKiKRGqJ9cwW645mYEOwWEqDxNUTYwRB88RsKZz-BjMwU&s=10', N'Phòng Queen Bắc Ninh.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('BN001_Q02', N'Queen 02', 'QUEEN', N'Trống', 'BN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRGcHios9GsQ4LKiKRGqJ9cwW645mYEOwWEqDxNUTYwRB88RsKZz-BjMwU&s=10', N'Phòng Queen ấm cúng Bắc Ninh.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('BN001_K01', N'King 01',  'KING',  N'Trống', 'BN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  N'Phòng King Bắc Ninh.', N'Máy chiếu 4K, PC Couple, Netflix 4K'),
('BN001_K02', N'King 02',  'KING',  N'Trống', 'BN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  N'Phòng King cao cấp Bắc Ninh.', N'Máy chiếu 4K, PC Couple, Netflix 4K'),

-- 8. Cơ sở HCM001 (Nguyễn Thái Bình - TP.HCM): 9 Box chủ đề
('HCM001_AN', N'Anime Box - Nguyễn Thái Bình',    'ANIME',    N'Trống', 'HCM001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQgnuuLUItNOj1YmFsJvW98wWDCgWbnn23M52Pit7Jhnw&s=10',    N'Phòng phong cách Anime Nhật Bản ấn tượng.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HCM001_AQ', N'Aquaman Box - Nguyễn Thái Bình',  'AQUAMAN',  N'Trống', 'HCM001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSNEbQwxT5t9KZ3tI31tzuVjCLgIg4xDDnFCnLe1jmV3s3M0SK8gvEZsLXm&s=10',  N'Không gian đại dương sâu thẳm Aquaman độc đáo.', N'Máy chiếu 4K, Sofa bed, Soundbar 5.1, Netflix 4K'),
('HCM001_AV', N'Avatar Box - Nguyễn Thái Bình',   'AVATAR',   N'Trống', 'HCM001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSIRWtXM0N9FJOChWCObhjkTX9n4YoGZgRiiwGNRP8bWjHNSAzT2aShxKo&s=10',    N'Vũ trụ Pandora huyền ảo.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HCM001_AG', N'Avenger Box - Nguyễn Thái Bình',  'AVENGER',  N'Đang dùng', 'HCM001', 'https://genzcinema.vn/wp-content/uploads/2024/11/avt-avenger-box-300x225.jpg',  N'Phòng Siêu anh hùng Marvel cá tính.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HCM001_FB', N'Football Box - Nguyễn Thái Bình', 'FOOTBALL', N'Trống', 'HCM001', 'https://genzcinema.vn/wp-content/uploads/2024/12/z6125888051970_3856ef75cfffba75cb94ab48c2590a20-scaled.jpg', N'Không gian điện ảnh kết hợp giải trí thể thao sôi động.', N'Máy chiếu 4K, Sofa bed, Soundbar, Netflix 4K'),
('HCM001_GM', N'Gaming Box - Nguyễn Thái Bình',   'GAMING',   N'Trống', 'HCM001', 'https://genzcinema.vn/wp-content/uploads/2024/11/football-box-1.jpg',   N'Phòng màn chiếu rộng kèm dàn PC đôi RTX chơi game đỉnh cao.', N'Máy chiếu 4K, PC Couple RTX, Sofa đôi, Netflix 4K'),
('HCM001_SK', N'Sakura Box - Nguyễn Thái Bình',   'SAKURA',   N'Trống', 'HCM001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQn2PiltApSB54I3vPB_xnR_CGMEpW80obAg2VrSSVBccBrfYPwIaMXVmX3&s=10',   N'Không gian hoa hoa anh đào Sakura lãng mạn.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HCM001_HK', N'HongKong Box - Nguyễn Thái Bình', 'HONGKONG', N'Trống', 'HCM001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRc71z8pXM0lGdrJ1o2b4hgyv8kwlEh1XHyiVkp0AdP4tRYL49Y1-Azza0&s=10', N'Phòng Hongkong Neon đêm huyền bí.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HCM001_TD', N'Teddy Box - Nguyễn Thái Bình',    'TEDDY',    N'Trống', 'HCM001', 'https://genzcinema.vn/wp-content/uploads/2025/06/11-768x576.png',    N'Không gian gấu Teddy đáng yêu và ấm áp.', N'Máy chiếu 4K, Gấu bông khổng lồ, Sofa bed, Netflix 4K'),

-- 9. Cơ sở HCM002 (Âu Cơ - TP.HCM): 2 Queen, 2 King
('HCM002_Q01', N'Queen 01', 'QUEEN', N'Trống', 'HCM002', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRGcHios9GsQ4LKiKRGqJ9cwW645mYEOwWEqDxNUTYwRB88RsKZz-BjMwU&s=10', N'Phòng Queen Âu Cơ.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HCM002_Q02', N'Queen 02', 'QUEEN', N'Trống', 'HCM002', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRGcHios9GsQ4LKiKRGqJ9cwW645mYEOwWEqDxNUTYwRB88RsKZz-BjMwU&s=10', N'Phòng Queen ấm cúng Âu Cơ.', N'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HCM002_K01', N'King 01',  'KING',  N'Trống', 'HCM002', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  N'Phòng King Âu Cơ có PC đôi.', N'Máy chiếu 4K, PC Couple, Netflix 4K'),
('HCM002_K02', N'King 02',  'KING',  N'Trống', 'HCM002', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  N'Phòng King sang trọng Âu Cơ.', N'Máy chiếu 4K, PC Couple, Netflix 4K');

-- User test cho Admin, Staff và Customer - Mật khẩu chung: Genz@123
INSERT INTO [User] (UserId, full_name, phone, email, password, RoleId, HotelId, IsLocked) VALUES
('SEED_ADMIN',    N'Trần Quản Lý (Admin)',  '0901111111', 'admin@genz.test',    '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'ADMIN',    NULL,    0),
('SEED_STAFF',    N'Lê Nhân Viên (Staff)',  '0902222222', 'staff@genz.test',    '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'STAFF',    'HN002', 0),
('STAFF_HN001',   N'Nguyễn Văn Thành (Staff)',   '0902222223', 'staff.hn001@genz.test','$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'STAFF',    'HN001', 0),
('STAFF_HCM001',  N'Phạm Hoàng Nam (Staff)', '0902222224', 'staff.hcm001@genz.test','$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'STAFF',    'HCM001',0),
('SEED_CUSTOMER', N'Nguyễn Văn An (Khách)', '0903333333', 'customer@genz.test', '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'CUSTOMER', NULL,    0),
('CUSTOMER_02',   N'Phạm Thị Mai',          '0904444444', 'mai.pham@genz.test', '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'CUSTOMER', NULL,    0),
('CUSTOMER_03',   N'Hoàng Minh Huy',        '0905555555', 'huy.hoang@genz.test','$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'CUSTOMER', NULL,    0),
('CUSTOMER_04',   N'Đặng Anh Tuấn',         '0906666666', 'tuan.dang@genz.test','$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'CUSTOMER', NULL,    0),
('CUSTOMER_05',   N'Trịnh Khánh Linh',      '0907777777', 'linh.trinh@genz.test','$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'CUSTOMER', NULL,    0),
('CUSTOMER_06',   N'Vũ Minh Hoàng',         '0908888888', 'hoang.vu@genz.test',  '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'CUSTOMER', NULL,    0);

-- Voucher ưu đãi thực tế GenZ Cinema
INSERT INTO Voucher (Code, Description, DiscountPercent, DiscountAmount, MinOrderAmount, ExpiryDate) VALUES
('GENZ30',    N'Ưu đãi Khai trương - Giảm 30% giá phòng',         30,   NULL,  0,      '2026-12-31'),
('COUPLE',    N'Gói hò hẹn lãng mạn cặp đôi - Giảm 50.000đ',       NULL, 50000, 200000, '2027-12-31'),
('GENZ10',    N'Giảm 10% cho thành viên GenZ Cinema',              10,   NULL,  0,      '2027-12-31'),
('NIGHTOWL',  N'Gói cày đêm cực phiêu - Giảm 40.000đ',             NULL, 40000, 180000, '2027-12-31'),
('STUDENT20', N'Ưu đãi Học sinh / Sinh viên GenZ - Giảm 20%',      20,   NULL,  0,      '2027-12-31'),
('VIPGIFT',   N'Quà tặng Khách hàng VIP GenZ - Giảm 100.000đ',     NULL, 100000,350000, '2027-12-31');

-- Thực đơn Đồ ăn & Thức uống (F&B) với URL Hình ảnh sắc nét
INSERT INTO FoodMenu (Name, Category, Price, ImageUrl, Description, IsAvailable) VALUES
(N'Nước ép Trái cây Tươi', N'Nước uống', 49000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTPq44HhMpLZ7BL-zWQeho22RteabBXpw1NQw7FdWWiqw&s=10', N'Nước ép cam, dưa hấu, táo tươi nguyên chất', 1),
(N'Sinh tố Bơ / Mãng cầu', N'Nước uống', 49000, 'https://lypham.vn/wp-content/uploads/2025/11/cach-lam-sinh-to-mang-cau-bo.jpg', N'Sinh tố bơ béo ngậy hoặc mãng cầu tươi mát', 1),
(N'Mỳ Ý Sốt Bò Băm (Spaghetti)', N'Đồ ăn Âu', 55000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSqoMdfpUqZa5L4Wow3YHle7zxEo8rY10wOLnCg9pcyFw&s=10', N'Mỳ Ý sốt cà chua bò băm phô mai thơm ngon', 1),
(N'Pizza Hải Sản / Bò Dứa Mini', N'Đồ ăn Âu', 89000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTx-DuQ0c6eb1V4-7SGJvxbdIXbjTXyNgJ0iPzSYXwdYQ&s=10', N'Pizza nướng giòn rụm đậm đà hương vị', 1),
(N'Set Combo Ăn Vặt GenZ', N'Set Combo', 79000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ3pXB85n3UPbIV3p24_-n4AoFC0_E2scBLaCd2RD-Dyg&s', N'Khoai tây chiên, gà lắc phô mai, cá viên chiên', 1),
(N'Chicken Love Set (Gà Rán + Nước)', N'Set Combo', 99000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQu1EIiAbLrHTPg7MoTYIdSA_bxiIR5fyrsp5tZVhR6rQ&s=10', N'Set gà giòn sốt cay nhẹ kèm 2 ly nước ngọt', 1),
(N'Bắp Nơ Bơ Tỏi (Popcorn 4K)', N'Mini Bar', 35000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTtf8eoQ7g7en8TMlIFybGAyq5_acDOim3q6j7paeW-KYqr-23Sh4HnkGUT&s=10', N'Bắp rang bơ giòn rụm vị caramel / phô mai', 1);

-- Danh sách 9 Phim HOT Đề Cử Chuẩn Theo Hình Ảnh GenZ Cinema
INSERT INTO Movie (Title, Category, Rating, Quality, PosterUrl, Description, IsHot) VALUES
(N'Quật mộ trùng ma', N'Kinh Dị', 4.9, '4K Netflix', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTcVYlbxp9q5WH1brR8iaT3bx7zm4BD6U71k94leFi2bQ&s=10', N'Phim kinh dị Hàn Quốc về các thực thể tâm linh xuất hiện sau vụ quật mộ bí ẩn.', 1),
(N'Godzilla x Kong: The New Empire', N'Hành Động', 5.0, '4K Netflix', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTOYLDdbqXvt4rvLa4S3dVO9i9qo0sEuIfu4XwEurAuTw&s=10', N'Cuộc đối đầu giữa các quái vật Godzilla và Kong khi titan mới xuất hiện.', 1),
(N'Một điều ước', N'Hài Hước', 4.8, '4K Full HD', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT5dbTwKB0Y55JttYFfFC55XUsD00zb6RW-v9O6F1_2KQ&s=10', N'Câu chuyện gia đình Việt đầy cảm xúc và thông điệp ấm áp về tình yêu và tình bạn.', 1),
(N'Kungfu Panda 4', N'Hoạt Hình', 4.9, '4K Full HD', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQuxQ_lk5uixOranAdVKhWjud5JQoKfzlFRM9fFsW2byw&s=10', N'Po cùng những người bạn đối đầu kẻ thù mới trong hành trình bảo vệ hòa bình.', 1),
(N'Night Swim', N'Kinh Dị', 4.7, '4K Netflix', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTowuRj5RGN5IE3DAzakLIa9t3ADFJMWGk0-TjcgZ41yQ&s=10', N'Câu chuyện về gia đình bị ám ảnh bởi thực thể ma quái từ hồ bơi trong căn nhà mới.', 1),
(N'Furiosa: A Mad Max Saga', N'Hành Động', 4.9, '4K Netflix', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTyKYgmLh7vCcCH28wp3ZPD0Wg6hL-14RX5Jui9AMFKkQ&s=10', N'Tiền truyện của Mad Max, xoay quanh hành trình của Furiosa trước sự kiện Mad Max.', 1),
(N'The Beekeeper', N'Kịch Tính', 4.8, '4K Full HD', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTKf9eMTGbAowqAOSf3-Cmgns_YWUvhoHxXsTVgo1yKTA&s=10', N'Jason Statham vào vai người nuôi ong báo thù sau cái chết của người thân yêu.', 1),
(N'Argylle Siêu Điệp Viên', N'Hành Động', 4.7, '4K Full HD', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRrWy2kSyIaCx3uTcAkGu9ENzoNbfLIIhDU10HQdj6Rsg&s=10', N'Một nữ nhà văn bị kéo vào những tình huống đời thực như trong sách của cô.', 1),
(N'Venom', N'Khoa Học', 4.9, '4K Netflix', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQE_KRFJf3PjRWvSL55ZLgT9bfMFc5VdNdkwB10ghrlPA&s', N'Eddie Brock - một nhà báo bị biến thành vật chủ của symbiote Venom.', 1);

-- Script dữ liệu Đặt phòng đa dạng (Phục vụ màn Admin Stats & Staff Management)
INSERT INTO Booking (RoomId, UserId, TypeBookingId, checkIn, checkOut, totalPrice, Status, voucherCode, discountAmount, note) VALUES
-- Đã hoàn thành (COMPLETED) - Đóng góp Doanh thu
('HN002_HK', 'SEED_CUSTOMER', 'TB_2H',    '2026-11-01 19:00', '2026-11-01 21:00', 276000, 'COMPLETED', NULL,     0,     N'Khách xem phim cặp đôi'),
('HN002_GM', 'CUSTOMER_02',   'TB_4H',    '2026-11-02 18:00', '2026-11-02 22:00', 326000, 'COMPLETED', 'GENZ10', 32600, N'Chơi PC Couple + Phim'),
('HCM001_HK','CUSTOMER_03',   'TB_NIGHT', '2026-11-02 23:00', '2026-11-03 07:00', 296000, 'COMPLETED', NULL,     0,     N'Trải nghiệm Homestay đêm'),
('HN001_Q01', 'CUSTOMER_04',   'TB_DAY',   '2026-11-03 07:00', '2026-11-03 12:00', 196000, 'COMPLETED', 'COUPLE', 50000, N'Combo hẹn hò sáng'),
('HN003_K01', 'SEED_CUSTOMER', 'TB_2H',    '2026-11-03 14:00', '2026-11-03 16:00', 286000, 'COMPLETED', NULL,     0,     N'Khách đặt xem phim lẻ'),

-- Đang diễn ra & Chờ duyệt (CHECKED_IN, CONFIRMED, PENDING, CANCELLED, REJECTED)
('HN001_K02', 'CUSTOMER_02',   'TB_2H',    '2026-11-03 14:00', '2026-11-03 16:00', 286000, 'CHECKED_IN', NULL,    0,     N'Khách đang ở phòng'),
('HN002_MV', 'CUSTOMER_03',   'TB_4H',    '2026-11-03 15:00', '2026-11-03 19:00', 296000, 'CHECKED_IN', NULL,    0,     N'Khách đang dùng phòng Marvel'),
('HCM001_AG','CUSTOMER_04',   'TB_NIGHT', '2026-11-03 23:00', '2026-11-04 07:00', 296000, 'CONFIRMED',  NULL,    0,     N'Staff đã xác nhận lịch hẹn'),
('HN002_HA', 'SEED_CUSTOMER', 'TB_2H',    '2026-11-04 19:00', '2026-11-04 21:00', 276000, 'PENDING',    NULL,    0,     N'Chờ Staff xác nhận'),
('HN004_K01', 'CUSTOMER_02',   'TB_2H',    '2026-11-03 10:00', '2026-11-03 12:00', 286000, 'CANCELLED',  NULL,    0,     N'Khách hủy do bận việc'),
('HCM001_AN', 'CUSTOMER_05',   'TB_2H',    '2026-11-04 14:00', '2026-11-04 16:00', 276000, 'PENDING',    'GENZ30',82800, N'Khách mới đặt phòng Anime Box'),
('HN001_Q02', 'CUSTOMER_06',   'TB_4H',    '2026-11-03 08:00', '2026-11-03 12:00', 296000, 'REJECTED',   NULL,    0,     N'Hết phòng trùng giờ');

-- Đánh giá khách hàng sinh động
INSERT INTO Review (BookingId, RoomId, UserId, Rating, Comment) VALUES
(1, 'HN002_HK', 'SEED_CUSTOMER', 5, N'Phòng Hongkong Neon cực kỳ đỉnh! Màn chiếu nét, bắp nước ngon, chắc chắn sẽ quay lại cùng người yêu.'),
(2, 'HN002_GM', 'CUSTOMER_02',   5, N'Giàn PC Couple cấu hình rất mạnh, chơi game mượt mà. Rạp phim riêng tư vô cùng thoải mái!'),
(3, 'HCM001_HK','CUSTOMER_03',   5, N'Trải nghiệm homestay đêm tuyệt vời tại cơ sở Nguyễn Thái Bình. Phòng ấm cúng, phục vụ chu đáo!'),
(4, 'HN001_Q01', 'CUSTOMER_04',   4, N'Phòng sạch sẽ, chiếu phim cực kỳ chất lượng. Nhân viên nhiệt tình phục vụ đồ ăn tận phòng.'),
(5, 'HN003_K01', 'SEED_CUSTOMER', 5, N'Phòng King rộng rãi, điều hòa mát rượi, âm thanh loa xịn vút tai!');

-- Thông báo phong phú dành cho Khách hàng & Staff các chi nhánh
INSERT INTO Notification (UserId, BookingId, Title, Message, IsRead) VALUES
-- Thông báo Khách hàng
('SEED_CUSTOMER', 1, N'Đặt phòng thành công! 🎟️', N'Mã đơn #1 tại GenZ Cinema Hoa Bằng - HongKong Box đã được ghi nhận.', 1),
('SEED_CUSTOMER', 1, N'Check-in thành công! 🔑', N'Chào mừng bạn đến phòng HongKong Box tại Hoa Bằng. Chúc bạn xem phim vui vẻ!', 1),
('SEED_CUSTOMER', 1, N'Cảm ơn bạn đã sử dụng dịch vụ! ⭐', N'Đơn #1 đã hoàn thành. Hãy chia sẻ trải nghiệm của bạn trên GenZ Cinema nhé!', 1),
('CUSTOMER_03',   8, N'Đặt phòng đã được xác nhận! ✅', N'Staff đã xác nhận booking Avenger Box tại cơ sở Nguyễn Thái Bình của bạn.', 0),
('CUSTOMER_05',   11,N'Đặt phòng thành công! 🎟️', N'Đơn #11 tại Nguyễn Thái Bình - Anime Box đang chờ Nhân viên xác nhận.', 0),

-- Thông báo dành cho Staff (Vận hành từng Chi nhánh)
('SEED_STAFF',    9, N'Đơn đặt phòng MỚI cần duyệt ⚡', N'Khách hàng Nguyễn Văn An vừa đặt phòng Hội An Box tại Hoa Bằng. Vui lòng kiểm tra và duyệt đơn.', 0),
('SEED_STAFF',    2, N'Yêu cầu dọn dẹp phòng 🧹', N'Phòng Gaming Box - Hoa Bằng vừa check-out. Vui lòng tiến hành dọn dẹp để đón lượt khách tiếp theo.', 1),
('STAFF_HN001',   6, N'Khách hàng đã Check-In 🔑', N'Khách hàng Phạm Thị Mai vừa check-in vào phòng King 02 tại Nguyễn Văn Lộc.', 0),
('STAFF_HN001',   12,N'Đơn đặt phòng BỊ TỪ CHỐI ❌', N'Đơn đặt phòng #12 tại Nguyễn Văn Lộc đã bị từ chối do trùng lịch.', 1),
('STAFF_HCM001',  11,N'Đơn đặt phòng MỚI cần duyệt ⚡', N'Khách hàng Trịnh Khánh Linh vừa đặt phòng Anime Box tại Nguyễn Thái Bình. Vui lòng kiểm tra.', 0),
('STAFF_HCM001',  3, N'Khách hàng đã Check-Out 🏁', N'Đơn #3 tại Nguyễn Thái Bình - HongKong Box đã hoàn thành thanh toán.', 1);
GO
