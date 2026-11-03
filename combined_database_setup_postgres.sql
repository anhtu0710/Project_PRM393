-- =============================================================================
-- GenzCinema Hotel — COMBINED DATABASE SETUP SCRIPT (PostgreSQL cho Aiven / Supabase / Neon / Render)
-- Dán trực tiếp TOÀN BỘ nội dung file này vào Query Editor của Aiven / Supabase / Render rồi bấm RUN / EXECUTE.
-- =============================================================================

-- 0. Xóa các bảng cũ nếu đã tồn tại (theo đúng thứ tự khóa ngoại)
DROP TABLE IF EXISTS Notification CASCADE;
DROP TABLE IF EXISTS Review CASCADE;
DROP TABLE IF EXISTS Booking CASCADE;
DROP TABLE IF EXISTS PasswordResetToken CASCADE;
DROP TABLE IF EXISTS PriceConfig CASCADE;
DROP TABLE IF EXISTS Room CASCADE;
DROP TABLE IF EXISTS FoodMenu CASCADE;
DROP TABLE IF EXISTS Movie CASCADE;
DROP TABLE IF EXISTS Voucher CASCADE;
DROP TABLE IF EXISTS TypeBooking CASCADE;
DROP TABLE IF EXISTS TypeRoom CASCADE;
DROP TABLE IF EXISTS Hotel CASCADE;
DROP TABLE IF EXISTS "user" CASCADE;
DROP TABLE IF EXISTS Role CASCADE;

-- 1. Bảng Hotel
CREATE TABLE IF NOT EXISTS Hotel (
    HotelId VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    countRoom INT DEFAULT 0,
    phone VARCHAR(20),
    imageUrl TEXT,
    City VARCHAR(100) NULL
);

-- 2. Bảng Role (Phân quyền)
CREATE TABLE IF NOT EXISTS Role (
    RoleId VARCHAR(50) PRIMARY KEY,
    RoleName VARCHAR(100) NOT NULL
);

-- 3. Bảng TypeRoom (Loại phòng / Box chủ đề)
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
    description TEXT NULL,
    amenities TEXT NULL,
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

-- 13. Bảng FoodMenu (Thực đơn F&B đồ ăn thức uống)
CREATE TABLE IF NOT EXISTS FoodMenu (
    FoodId SERIAL PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Category VARCHAR(100) NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    ImageUrl TEXT NULL,
    Description TEXT NULL,
    IsAvailable BOOLEAN NOT NULL DEFAULT TRUE
);

-- 14. Bảng Movie (Danh sách Phim Hot đề cử)
CREATE TABLE IF NOT EXISTS Movie (
    MovieId SERIAL PRIMARY KEY,
    Title VARCHAR(255) NOT NULL,
    Category VARCHAR(100) NOT NULL,
    Rating DECIMAL(3,1) NOT NULL DEFAULT 5.0,
    Quality VARCHAR(50) NOT NULL DEFAULT '4K Netflix',
    PosterUrl TEXT NULL,
    Description TEXT NULL,
    IsHot BOOLEAN NOT NULL DEFAULT TRUE
);

-- =============================================================================
-- SEED DATA CHUẨN ĐÚNG YÊU CẦU GENZCINEMA (POSTGRESQL)
-- =============================================================================

INSERT INTO Role (RoleId, RoleName) VALUES
('ADMIN', 'Administrator'),
('STAFF', 'Staff'),
('CUSTOMER', 'Customer')
ON CONFLICT (RoleId) DO NOTHING;

-- Tất cả các Loại phòng Box chủ đề
INSERT INTO TypeRoom (TypeRoomId, TypeRoom, pricePerHour) VALUES
('QUEEN',    'Phòng Queen',   96000),
('KING',     'Phòng King',    106000),
('FOOTBALL', 'Football Box',  106000),
('GAMING',   'Gaming Box',    106000),
('HOIAN',    'Hội An Box',    96000),
('HONGKONG', 'HongKong Box',  96000),
('MARVEL',   'Marvel Box',    96000),
('NATRA',    'Natra Box',     96000),
('SAMURAI',  'Samurai Box',   96000),
('ANIME',    'Anime Box',     96000),
('AQUAMAN',  'Aquaman Box',   96000),
('AVATAR',   'Avatar Box',    96000),
('AVENGER',  'Avenger Box',   96000),
('SAKURA',   'Sakura Box',    96000),
('TEDDY',    'Teddy Box',     96000)
ON CONFLICT (TypeRoomId) DO NOTHING;

-- Các gói thuê
INSERT INTO TypeBooking (TypeBookingId, TypeName, BookingCode, DurationHours) VALUES
('TB_HOURLY', 'Thuê theo giờ',                    'HOURLY',      1),
('TB_2H',     'Combo 2h xem phim + đồ ăn',        'COMBO_2H',    2),
('TB_4H',     'Combo 4h xem phim + đồ ăn',        'COMBO_4H',    4),
('TB_5H',     'Combo 5h giải trí',                'COMBO_5H',    5),
('TB_6H',     'Combo 6h giải trí',                'COMBO_6H',    6),
('TB_DAY',    'Combo ngày 7h-12h (1 nước pha chế)', 'COMBO_DAY',   5),
('TB_NIGHT',  'Combo đêm 23h-7h (1 nước pha chế)',  'COMBO_NIGHT', 8)
ON CONFLICT (TypeBookingId) DO NOTHING;

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

-- Danh sách 9 Chi nhánh
INSERT INTO Hotel (HotelId, name, address, countRoom, phone, imageUrl, City) VALUES
('HN001', 'GenZ Cinema - Nguyễn Văn Lộc',   'Số 13, Ngõ 2 Nguyễn Văn Lộc, P. Mộ Lao, Hà Đông, Hà Nội',          4, '0876583333', 'https://genzcinema.vn/wp-content/uploads/2024/01/hadong.jpg', 'Hà Nội'),
('HN002', 'GenZ Cinema - Hoa Bằng',        'Số 24 P. Hoa Bằng, Yên Hoà, Cầu Giấy, Hà Nội',                     7, '0877155379', 'https://genzcinema.vn/wp-content/uploads/2024/01/caugiay.jpg', 'Hà Nội'),
('HN003', 'GenZ Cinema - Nguyễn Lương Bằng', 'Số 3, Ngõ 180 Nguyễn Lương Bằng, Quang Trung, Đống Đa, Hà Nội',    4, '0325186385', 'https://genzcinema.vn/wp-content/uploads/2024/01/dongda.jpg', 'Hà Nội'),
('HN004', 'GenZ Cinema - Hoàng Ngân',       'Số 103 P. Hoàng Ngân, Nhân Chính, Thanh Xuân, Hà Nội',             4, '0823983881', 'https://genzcinema.vn/wp-content/uploads/2024/01/thanhxuan.jpg', 'Hà Nội'),
('HN005', 'GenZ Cinema - Lĩnh Nam',         'Số 130 P. Lĩnh Nam, Vĩnh Hưng, Hoàng Mai, Hà Nội',                 4, '0989838603', 'https://genzcinema.vn/wp-content/uploads/2024/01/linhnam.jpg', 'Hà Nội'),
('HN006', 'GenZ Cinema - Hồ Tây',           'Số 135 P. Nhật Chiêu, Nhật Tân, Tây Hồ, Hà Nội',                  4, '0838408881', 'https://genzcinema.vn/wp-content/uploads/2024/01/tayho.jpg', 'Hà Nội'),
('BN001', 'GenZ Cinema - Lý Đạo Thành',     'Số 63 P. Lý Đạo Thành, TP. Bắc Ninh',                             4, '0876583333', 'https://genzcinema.vn/wp-content/uploads/2024/01/bacninh.jpg', 'Bắc Ninh'),
('HCM001', 'GenZ Cinema - Nguyễn Thái Bình','Số 419 Nguyễn Thái Bình, P. 12, Q. Tân Bình, TP. Hồ Chí Minh',     9, '0876583333', 'https://genzcinema.vn/wp-content/uploads/2024/01/tanbinh.jpg', 'TP. Hồ Chí Minh'),
('HCM002', 'GenZ Cinema - Âu Cơ',          'Số 547 Âu Cơ, P. Phú Trung, Q. Tân Phú, TP. Hồ Chí Minh',          4, '0876583333', 'https://genzcinema.vn/wp-content/uploads/2024/01/tanphu.jpg', 'TP. Hồ Chí Minh')
ON CONFLICT (HotelId) DO NOTHING;

-- Danh sách Phòng đúng chuẩn phân bổ yêu cầu
INSERT INTO Room (RoomId, nameRoom, TypeRoomId, Status, HotelId, imageUrl, description, amenities) VALUES
-- 1. Cơ sở HN001 (Nguyễn Văn Lộc): 2 Queen, 2 King
('HN001_Q01', 'Queen 01', 'QUEEN', 'Trống', 'HN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Phòng Queen chiếu phim riêng tư ấm cúng.', 'Máy chiếu 4K, Sofa bed, Điều hòa 2 chiều, Netflix 4K'),
('HN001_Q02', 'Queen 02', 'QUEEN', 'Trống', 'HN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Phòng Queen xem phim không gian thoáng mát.', 'Máy chiếu 4K, Sofa bed, Máy lọc không khí, Netflix 4K'),
('HN001_K01', 'King 01',  'KING',  'Trống', 'HN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phòng King cao cấp trang bị PC đôi chơi game.', 'Máy chiếu 4K, PC Couple RTX, Sofa đôi, Netflix 4K'),
('HN001_K02', 'King 02',  'KING',  'Đang dùng', 'HN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phòng King rạp chiếu phim kết hợp dàn máy gaming.', 'Máy chiếu 4K, PC Couple RTX, Sofa đôi, Board game'),

-- 2. Cơ sở HN002 (Hoa Bằng - Hà Nội): 7 Box chủ đề
('HN002_FB', 'Football Box - Hoa Bằng', 'FOOTBALL', 'Trống', 'HN002', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Không gian điện ảnh kết hợp giải trí thể thao sôi động.', 'Máy chiếu 4K, Sofa bed, Soundbar 5.1, Netflix 4K'),
('HN002_GM', 'Gaming Box - Hoa Bằng',   'GAMING',   'Trống', 'HN002', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',   'Màn chiếu rộng kết hợp giàn PC đôi chơi game cực mượt.', 'Máy chiếu 4K, PC Couple RTX, Sofa đôi, Netflix 4K'),
('HN002_HA', 'Hội An Box - Hoa Bằng',   'HOIAN',    'Trống', 'HN002', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',    'Không gian phố cổ Hội An lãng mạn hoài niệm.', 'Máy chiếu 4K, Sofa bed, Đèn lồng trang trí, Netflix 4K'),
('HN002_HK', 'HongKong Box - Hoa Bằng', 'HONGKONG', 'Trống', 'HN002', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Bầu không khí phố đêm Hongkong Neon cực chất.', 'Máy chiếu 4K, Sofa bed, Netflix 4K, Board game'),
('HN002_MV', 'Marvel Box - Hoa Bằng',   'MARVEL',   'Đang dùng', 'HN002', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phong cách Siêu anh hùng Marvel cá tính.', 'Máy chiếu 4K, Sofa bed, Âm thanh surround, Netflix 4K'),
('HN002_NT', 'Natra Box - Hoa Bằng',    'NATRA',    'Trống', 'HN002', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',    'Không gian huyền thoại Natra Ma Đồng Giáng Thế.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN002_SR', 'Samurai Box - Hoa Bằng',  'SAMURAI',  'Trống', 'HN002', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phong cách võ sĩ Samurai Nhật Bản ấn tượng.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),

-- 3. Cơ sở HN003 (Nguyễn Lương Bằng): 2 Queen, 2 King
('HN003_Q01', 'Queen 01', 'QUEEN', 'Trống', 'HN003', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Phòng Queen riêng tư.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN003_Q02', 'Queen 02', 'QUEEN', 'Trống', 'HN003', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Phòng Queen ngọt ngào.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN003_K01', 'King 01',  'KING',  'Trống', 'HN003', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phòng King có PC đôi.', 'Máy chiếu 4K, PC Couple, Netflix 4K'),
('HN003_K02', 'King 02',  'KING',  'Trống', 'HN003', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phòng King rộng rãi.', 'Máy chiếu 4K, PC Couple, Netflix 4K'),

-- 4. Cơ sở HN004 (Hoàng Ngân): 2 Queen, 2 King
('HN004_Q01', 'Queen 01', 'QUEEN', 'Trống', 'HN004', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Phòng Queen riêng tư.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN004_Q02', 'Queen 02', 'QUEEN', 'Trống', 'HN004', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Phòng Queen hiện đại.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN004_K01', 'King 01',  'KING',  'Đang dọn', 'HN004', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phòng King sang trọng.', 'Máy chiếu 4K, PC Couple, Netflix 4K'),
('HN004_K02', 'King 02',  'KING',  'Trống', 'HN004', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phòng King đầy đủ tiện nghi.', 'Máy chiếu 4K, PC Couple, Netflix 4K'),

-- 5. Cơ sở HN005 (Lĩnh Nam): 2 Queen, 2 King
('HN005_Q01', 'Queen 01', 'QUEEN', 'Trống', 'HN005', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Phòng Queen Lĩnh Nam.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN005_Q02', 'Queen 02', 'QUEEN', 'Trống', 'HN005', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Phòng Queen thư giãn.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN005_K01', 'King 01',  'KING',  'Trống', 'HN005', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phòng King PC đôi Lĩnh Nam.', 'Máy chiếu 4K, PC Couple, Netflix 4K'),
('HN005_K02', 'King 02',  'KING',  'Trống', 'HN005', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phòng King cao cấp Lĩnh Nam.', 'Máy chiếu 4K, PC Couple, Netflix 4K'),

-- 6. Cơ sở HN006 (Hồ Tây): 2 Queen, 2 King
('HN006_Q01', 'Queen 01', 'QUEEN', 'Trống', 'HN006', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Phòng Queen view Hồ Tây.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN006_Q02', 'Queen 02', 'QUEEN', 'Trống', 'HN006', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Phòng Queen lãng mạn Hồ Tây.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HN006_K01', 'King 01',  'KING',  'Đang dùng', 'HN006', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phòng King Hồ Tây với PC đôi.', 'Máy chiếu 4K, PC Couple, Netflix 4K'),
('HN006_K02', 'King 02',  'KING',  'Trống', 'HN006', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phòng King sang trọng Hồ Tây.', 'Máy chiếu 4K, PC Couple, Netflix 4K'),

-- 7. Cơ sở BN001 (Lý Đạo Thành - Bắc Ninh): 2 Queen, 2 King
('BN001_Q01', 'Queen 01', 'QUEEN', 'Trống', 'BN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Phòng Queen Bắc Ninh.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('BN001_Q02', 'Queen 02', 'QUEEN', 'Trống', 'BN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Phòng Queen ấm cúng Bắc Ninh.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('BN001_K01', 'King 01',  'KING',  'Trống', 'BN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phòng King Bắc Ninh.', 'Máy chiếu 4K, PC Couple, Netflix 4K'),
('BN001_K02', 'King 02',  'KING',  'Trống', 'BN001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phòng King cao cấp Bắc Ninh.', 'Máy chiếu 4K, PC Couple, Netflix 4K'),

-- 8. Cơ sở HCM001 (Nguyễn Thái Bình - TP.HCM): 9 Box chủ đề
('HCM001_AN', 'Anime Box - Nguyễn Thái Bình',    'ANIME',    'Trống', 'HCM001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',    'Phòng phong cách Anime Nhật Bản ấn tượng.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HCM001_AQ', 'Aquaman Box - Nguyễn Thái Bình',  'AQUAMAN',  'Trống', 'HCM001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Không gian đại dương sâu thẳm Aquaman độc đáo.', 'Máy chiếu 4K, Sofa bed, Soundbar 5.1, Netflix 4K'),
('HCM001_AV', 'Avatar Box - Nguyễn Thái Bình',   'AVATAR',   'Trống', 'HCM001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',    'Vũ trụ Pandora huyền ảo.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HCM001_AG', 'Avenger Box - Nguyễn Thái Bình',  'AVENGER',  'Đang dùng', 'HCM001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phòng Siêu anh hùng Marvel cá tính.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HCM001_FB', 'Football Box - Nguyễn Thái Bình', 'FOOTBALL', 'Trống', 'HCM001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Không gian điện ảnh kết hợp thể thao sôi động.', 'Máy chiếu 4K, Sofa bed, Soundbar, Netflix 4K'),
('HCM001_GM', 'Gaming Box - Nguyễn Thái Bình',   'GAMING',   'Trống', 'HCM001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',   'Phòng màn chiếu rộng kèm dàn PC đôi RTX chơi game đỉnh cao.', 'Máy chiếu 4K, PC Couple RTX, Sofa đôi, Netflix 4K'),
('HCM001_SK', 'Sakura Box - Nguyễn Thái Bình',   'SAKURA',   'Trống', 'HCM001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',   'Không gian hoa hoa anh đào Sakura lãng mạn.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HCM001_HK', 'HongKong Box - Nguyễn Thái Bình', 'HONGKONG', 'Trống', 'HCM001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Phòng Hongkong Neon đêm huyền bí.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HCM001_TD', 'Teddy Box - Nguyễn Thái Bình',    'TEDDY',    'Trống', 'HCM001', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',    'Không gian gấu Teddy đáng yêu và ấm áp.', 'Máy chiếu 4K, Gấu bông khổng lồ, Sofa bed, Netflix 4K'),

-- 9. Cơ sở HCM002 (Âu Cơ - TP.HCM): 2 Queen, 2 King
('HCM002_Q01', 'Queen 01', 'QUEEN', 'Trống', 'HCM002', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Phòng Queen Âu Cơ.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HCM002_Q02', 'Queen 02', 'QUEEN', 'Trống', 'HCM002', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10', 'Phòng Queen ấm cúng Âu Cơ.', 'Máy chiếu 4K, Sofa bed, Netflix 4K'),
('HCM002_K01', 'King 01',  'KING',  'Trống', 'HCM002', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phòng King Âu Cơ có PC đôi.', 'Máy chiếu 4K, PC Couple, Netflix 4K'),
('HCM002_K02', 'King 02',  'KING',  'Trống', 'HCM002', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQP6Qu07F17Eg7f3s3S374SAuaOSBL7_azsrB4lcocbzg&s=10',  'Phòng King sang trọng Âu Cơ.', 'Máy chiếu 4K, PC Couple, Netflix 4K')
ON CONFLICT (RoomId) DO NOTHING;

-- User test cho Admin, Staff và Customer - Mật khẩu chung: Genz@123
INSERT INTO "user" (UserId, full_name, phone, email, password, RoleId, IsLocked) VALUES
('SEED_ADMIN',    'Trần Quản Lý (Admin)',  '0901111111', 'admin@genz.test',    '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'ADMIN',    FALSE),
('SEED_STAFF',    'Lê Nhân Viên (Staff)',  '0902222222', 'staff@genz.test',    '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'STAFF',    FALSE),
('SEED_CUSTOMER', 'Nguyễn Văn An (Khách)', '0903333333', 'customer@genz.test', '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'CUSTOMER', FALSE),
('CUSTOMER_02',   'Phạm Thị Mai',          '0904444444', 'mai.pham@genz.test', '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'CUSTOMER', FALSE),
('CUSTOMER_03',   'Hoàng Minh Huy',        '0905555555', 'huy.hoang@genz.test','$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'CUSTOMER', FALSE),
('CUSTOMER_04',   'Đặng Anh Tuấn',         '0906666666', 'tuan.dang@genz.test','$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'CUSTOMER', FALSE)
ON CONFLICT (UserId) DO NOTHING;

-- Voucher ưu đãi thực tế GenZ Cinema
INSERT INTO Voucher (Code, Description, DiscountPercent, DiscountAmount, MinOrderAmount, ExpiryDate) VALUES
('GENZ30',  'Ưu đãi Khai trương - Giảm 30% giá phòng',         30,   NULL,  0,      '2026-12-31 23:59:59'),
('COUPLE',  'Gói hò hẹn lãng mạn cặp đôi - Giảm 50.000đ',       NULL, 50000, 200000, '2027-12-31 23:59:59'),
('GENZ10',  'Giảm 10% cho thành viên GenZ Cinema',              10,   NULL,  0,      '2027-12-31 23:59:59')
ON CONFLICT (Code) DO NOTHING;

-- Thực đơn Đồ ăn & Thức uống (F&B) với URL Hình ảnh sắc nét
INSERT INTO FoodMenu (Name, Category, Price, ImageUrl, Description, IsAvailable) VALUES
('Nước ép Trái cây Tươi', 'Nước uống', 49000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTPq44HhMpLZ7BL-zWQeho22RteabBXpw1NQw7FdWWiqw&s=10', 'Nước ép cam, dưa hấu, táo tươi nguyên chất', TRUE),
('Sinh tố Bơ / Mãng cầu', 'Nước uống', 49000, 'https://lypham.vn/wp-content/uploads/2025/11/cach-lam-sinh-to-mang-cau-bo.jpg', 'Sinh tố bơ béo ngậy hoặc mãng cầu tươi mát', TRUE),
('Mỳ Ý Sốt Bò Băm (Spaghetti)', 'Đồ ăn Âu', 55000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSqoMdfpUqZa5L4Wow3YHle7zxEo8rY10wOLnCg9pcyFw&s=10', 'Mỳ Ý sốt cà chua bò băm phô mai thơm ngon', TRUE),
('Pizza Hải Sản / Bò Dứa Mini', 'Đồ ăn Âu', 89000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTx-DuQ0c6eb1V4-7SGJvxbdIXbjTXyNgJ0iPzSYXwdYQ&s=10', 'Pizza nướng giòn rụm đậm đà hương vị', TRUE),
('Set Combo Ăn Vặt GenZ', 'Set Combo', 79000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ3pXB85n3UPbIV3p24_-n4AoFC0_E2scBLaCd2RD-Dyg&s', 'Khoai tây chiên, gà lắc phô mai, cá viên chiên', TRUE),
('Chicken Love Set (Gà Rán + Nước)', 'Set Combo', 99000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQu1EIiAbLrHTPg7MoTYIdSA_bxiIR5fyrsp5tZVhR6rQ&s=10', 'Set gà giòn sốt cay nhẹ kèm 2 ly nước ngọt', TRUE),
('Bắp Nơ Bơ Tỏi (Popcorn 4K)', 'Mini Bar', 35000, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTtf8eoQ7g7en8TMlIFybGAyq5_acDOim3q6j7paeW-KYqr-23Sh4HnkGUT&s=10', 'Bắp rang bơ giòn rụm vị caramel / phô mai', TRUE);

-- Danh sách 9 Phim HOT Đề Cử Chuẩn Theo Hình Ảnh GenZ Cinema
INSERT INTO Movie (Title, Category, Rating, Quality, PosterUrl, Description, IsHot) VALUES
('Quật mộ trùng ma', 'Kinh Dị', 4.9, '4K Netflix', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTcVYlbxp9q5WH1brR8iaT3bx7zm4BD6U71k94leFi2bQ&s=10', 'Phim kinh dị Hàn Quốc về các thực thể tâm linh xuất hiện sau vụ quật mộ bí ẩn.', TRUE),
('Godzilla x Kong: The New Empire', 'Hành Động', 5.0, '4K Netflix', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTOYLDdbqXvt4rvLa4S3dVO9i9qo0sEuIfu4XwEurAuTw&s=10', 'Cuộc đối đầu giữa các quái vật Godzilla và Kong khi titan mới xuất hiện.', TRUE),
('Một điều ước', 'Hài Hước', 4.8, '4K Full HD', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT5dbTwKB0Y55JttYFfFC55XUsD00zb6RW-v9O6F1_2KQ&s=10', 'Câu chuyện gia đình Việt đầy cảm xúc và thông điệp ấm áp về tình yêu và tình bạn.', TRUE),
('Kungfu Panda 4', 'Hoạt Hình', 4.9, '4K Full HD', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQuxQ_lk5uixOranAdVKhWjud5JQoKfzlFRM9fFsW2byw&s=10', 'Po cùng những người bạn đối đầu kẻ thù mới trong hành trình bảo vệ hòa bình.', TRUE),
('Night Swim', 'Kinh Dị', 4.7, '4K Netflix', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTowuRj5RGN5IE3DAzakLIa9t3ADFJMWGk0-TjcgZ41yQ&s=10', 'Câu chuyện về gia đình bị ám ảnh bởi thực thể ma quái từ hồ bơi trong căn nhà mới.', TRUE),
('Furiosa: A Mad Max Saga', 'Hành Động', 4.9, '4K Netflix', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTyKYgmLh7vCcCH28wp3ZPD0Wg6hL-14RX5Jui9AMFKkQ&s=10', 'Tiền truyện của Mad Max, xoay quanh hành trình của Furiosa trước sự kiện Mad Max.', TRUE),
('The Beekeeper', 'Kịch Tính', 4.8, '4K Full HD', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTKf9eMTGbAowqAOSf3-Cmgns_YWUvhoHxXsTVgo1yKTA&s=10', 'Jason Statham vào vai người nuôi ong báo thù sau cái chết của người thân yêu.', TRUE),
('Argylle Siêu Điệp Viên', 'Hành Động', 4.7, '4K Full HD', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRrWy2kSyIaCx3uTcAkGu9ENzoNbfLIIhDU10HQdj6Rsg&s=10', 'Một nữ nhà văn bị kéo vào những tình huống đời thực như trong sách của cô.', TRUE),
('Venom', 'Khoa Học', 4.9, '4K Netflix', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQE_KRFJf3PjRWvSL55ZLgT9bfMFc5VdNdkwB10ghrlPA&s', 'Eddie Brock - một nhà báo bị biến thành vật chủ của symbiote Venom.', TRUE);

-- Script dữ liệu Đặt phòng đa dạng (Phục vụ màn Admin Stats & Staff Management)
INSERT INTO Booking (RoomId, UserId, TypeBookingId, checkIn, checkOut, totalPrice, Status, voucherCode, discountAmount, note) VALUES
('HN002_HK', 'SEED_CUSTOMER', 'TB_2H',    '2026-11-01 19:00:00', '2026-11-01 21:00:00', 276000, 'COMPLETED', NULL,     0,     'Khách xem phim cặp đôi'),
('HN002_GM', 'CUSTOMER_02',   'TB_4H',    '2026-11-02 18:00:00', '2026-11-02 22:00:00', 326000, 'COMPLETED', 'GENZ10', 32600, 'Chơi PC Couple + Phim'),
('HCM001_HK','CUSTOMER_03',   'TB_NIGHT', '2026-11-02 23:00:00', '2026-11-03 07:00:00', 296000, 'COMPLETED', NULL,     0,     'Trải nghiệm Homestay đêm'),
('HN001_Q01', 'CUSTOMER_04',   'TB_DAY',   '2026-11-03 07:00:00', '2026-11-03 12:00:00', 196000, 'COMPLETED', 'COUPLE', 50000, 'Combo hẹn hò sáng'),
('HN003_K01', 'SEED_CUSTOMER', 'TB_2H',    '2026-11-03 14:00:00', '2026-11-03 16:00:00', 286000, 'COMPLETED', NULL,     0,     'Khách đặt xem phim lẻ'),
('HN001_K02', 'CUSTOMER_02',   'TB_2H',    '2026-11-03 14:00:00', '2026-11-03 16:00:00', 286000, 'CHECKED_IN', NULL,    0,     'Khách đang ở phòng'),
('HN002_MV', 'CUSTOMER_03',   'TB_4H',    '2026-11-03 15:00:00', '2026-11-03 19:00:00', 296000, 'CHECKED_IN', NULL,    0,     'Khách đang dùng phòng Marvel'),
('HCM001_AG','CUSTOMER_04',   'TB_NIGHT', '2026-11-03 23:00:00', '2026-11-04 07:00:00', 296000, 'CONFIRMED',  NULL,    0,     'Staff đã xác nhận lịch hẹn'),
('HN002_HA', 'SEED_CUSTOMER', 'TB_2H',    '2026-11-04 19:00:00', '2026-11-04 21:00:00', 276000, 'PENDING',    NULL,    0,     'Chờ Staff xác nhận'),
('HN004_K01', 'CUSTOMER_02',   'TB_2H',    '2026-11-03 10:00:00', '2026-11-03 10:00:00', 286000, 'CANCELLED',  NULL,    0,     'Khách hủy do bận việc');

-- Đánh giá khách hàng sinh động
INSERT INTO Review (BookingId, RoomId, UserId, Rating, Comment) VALUES
(1, 'HN002_HK', 'SEED_CUSTOMER', 5, 'Phòng Hongkong Neon cực kỳ đỉnh! Màn chiếu nét, bắp nước ngon, chắc chắn sẽ quay lại cùng người yêu.'),
(2, 'HN002_GM', 'CUSTOMER_02',   5, 'Giàn PC Couple cấu hình rất mạnh, chơi game mượt mà. Rạp phim riêng tư vô cùng thoải mái!'),
(3, 'HCM001_HK','CUSTOMER_03',   5, 'Trải nghiệm homestay đêm tuyệt vời tại cơ sở Nguyễn Thái Bình. Phòng ấm cúng, phục vụ chu đáo!');

-- Thông báo mẫu cho người dùng
INSERT INTO Notification (UserId, BookingId, Title, Message) VALUES
('SEED_CUSTOMER', 1, 'Đặt phòng thành công', 'Cảm ơn bạn đã đặt phòng tại GenZ Cinema Hoa Bằng!'),
('CUSTOMER_03',   8, 'Xác nhận lịch hẹn', 'Staff đã xác nhận booking Avenger Box tại cơ sở Nguyễn Thái Bình của bạn.');
