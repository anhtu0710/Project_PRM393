-- =============================================================================
-- GenzCinema Hotel — Nền móng database cho sprint
-- Chạy 1 LẦN, SAU file SQLQuery1.sql. Mở file trong SSMS rồi bấm Execute.
--
-- Tài khoản test (mật khẩu chung: Genz@123):
--   admin@genz.test    — ADMIN
--   staff@genz.test    — STAFF
--   customer@genz.test — CUSTOMER
-- =============================================================================

USE GenzCinemaHotel;
GO

-- 1. Bảng User: thêm cột khoá tài khoản (0 = bình thường, 1 = bị khoá)
ALTER TABLE [User] ADD IsLocked BIT NOT NULL DEFAULT 0;
GO

-- 2. Trạng thái booking dùng tên mới:
--    PENDING, CONFIRMED, REJECTED, CHECKED_IN, COMPLETED, CANCELLED
UPDATE Booking SET Status = 'PENDING' WHERE Status = N'Chưa thanh toán';

-- 3. Bảng Voucher: chỉ điền 1 trong 2 cột giảm giá (% hoặc số tiền)
CREATE TABLE Voucher (
    VoucherId       INT IDENTITY(1,1) PRIMARY KEY,
    Code            VARCHAR(50)    NOT NULL UNIQUE,
    Description     NVARCHAR(255)  NULL,
    DiscountPercent DECIMAL(5, 2)  NULL,          -- VD: 10 = giảm 10%
    DiscountAmount  DECIMAL(18, 2) NULL,          -- VD: 50000 = giảm 50.000đ
    MinOrderAmount  DECIMAL(18, 2) NOT NULL DEFAULT 0,
    ExpiryDate      DATETIME       NOT NULL
);

-- 4. Bảng Review: mỗi booking chỉ đánh giá 1 lần (BookingId UNIQUE)
CREATE TABLE Review (
    ReviewId  INT IDENTITY(1,1) PRIMARY KEY,
    BookingId INT           NOT NULL UNIQUE,
    RoomId    VARCHAR(50)   NOT NULL,
    UserId    VARCHAR(50)   NOT NULL,
    Rating    INT           NOT NULL,             -- 1 đến 5 sao
    Comment   NVARCHAR(MAX) NULL,
    CreatedAt DATETIME      NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (BookingId) REFERENCES Booking(BookingId),
    FOREIGN KEY (RoomId)    REFERENCES Room(RoomId),
    FOREIGN KEY (UserId)    REFERENCES [User](UserId)
);

-- 5. Bảng Notification: thông báo gửi cho 1 người dùng
CREATE TABLE Notification (
    NotificationId INT IDENTITY(1,1) PRIMARY KEY,
    UserId    VARCHAR(50)   NOT NULL,             -- người nhận
    BookingId INT           NULL,                 -- booking liên quan (có thể trống)
    Title     NVARCHAR(255) NOT NULL,
    Message   NVARCHAR(MAX) NOT NULL,
    IsRead    BIT           NOT NULL DEFAULT 0,   -- 0 = chưa đọc
    CreatedAt DATETIME      NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (UserId)    REFERENCES [User](UserId),
    FOREIGN KEY (BookingId) REFERENCES Booking(BookingId)
);
GO

-- =============================================================================
-- DỮ LIỆU MẪU
-- =============================================================================

-- 6. Tài khoản test — mật khẩu Genz@123 đã được mã hoá BCrypt
INSERT INTO [User] (UserId, full_name, phone, email, password, RoleId, IsLocked) VALUES
('SEED_ADMIN',    N'Admin Test', '0900000001', 'admin@genz.test',    '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'ADMIN',    0),
('SEED_STAFF',    N'Staff Test', '0900000002', 'staff@genz.test',    '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'STAFF',    0),
('SEED_CUSTOMER', N'Khách Test', '0900000003', 'customer@genz.test', '$2a$10$OMZHCh3Pq0dx9lbPxrpfuONX78NID88mpdCDC7kVLQBTNCh8xVuyy', 'CUSTOMER', 0);

-- 7. Voucher mẫu
INSERT INTO Voucher (Code, Description, DiscountPercent, DiscountAmount, MinOrderAmount, ExpiryDate) VALUES
('GENZ10',  N'Giảm 10% mọi đơn',                         10,   NULL,  0,      '2027-12-31'),
('GIAM50K', N'Giảm 50.000đ cho đơn từ 250.000đ',         NULL, 50000, 250000, '2027-12-31'),
('HETHAN',  N'Voucher đã hết hạn, dùng để test báo lỗi', 20,   NULL,  0,      '2025-01-01');

-- 8. Booking mẫu của customer@genz.test (giá lấy đúng từ bảng PriceConfig)
INSERT INTO Booking (RoomId, UserId, TypeBookingId, checkIn, checkOut, totalPrice, Status, voucherCode, discountAmount, note) VALUES
-- Đã qua: dùng cho dashboard doanh thu và đánh giá
('HN001_Q01', 'SEED_CUSTOMER', 'TB_2H',    '2026-11-01 19:00', '2026-11-01 21:00', 276000, 'COMPLETED', NULL,     0,     N'Dữ liệu mẫu'),
('HN001_K01', 'SEED_CUSTOMER', 'TB_4H',    '2026-10-31 18:00', '2026-10-31 22:00', 326000, 'COMPLETED', NULL,     0,     N'Dữ liệu mẫu'),
('HN002_Q01', 'SEED_CUSTOMER', 'TB_NIGHT', '2026-10-30 23:00', '2026-10-31 07:00', 296000, 'COMPLETED', NULL,     0,     N'Dữ liệu mẫu'),
('HN003_K02', 'SEED_CUSTOMER', 'TB_DAY',   '2026-10-28 07:00', '2026-10-28 12:00', 221400, 'COMPLETED', 'GENZ10', 24600, N'Dữ liệu mẫu'),
('HN005_Q02', 'SEED_CUSTOMER', 'TB_6H',    '2026-10-25 14:00', '2026-10-25 20:00', 416000, 'COMPLETED', NULL,     0,     N'Dữ liệu mẫu'),
('HN002_K01', 'SEED_CUSTOMER', 'TB_2H',    '2026-10-29 20:00', '2026-10-29 22:00', 286000, 'CANCELLED', NULL,     0,     N'Dữ liệu mẫu'),
-- Sắp tới: dùng cho staff duyệt và check-in
('HN001_Q02', 'SEED_CUSTOMER', 'TB_2H',    '2026-11-05 19:00', '2026-11-05 21:00', 276000, 'PENDING',   NULL,     0,     N'Dữ liệu mẫu'),
('HN006_Q01', 'SEED_CUSTOMER', 'TB_5H',    '2026-11-05 14:00', '2026-11-05 19:00', 366000, 'PENDING',   NULL,     0,     N'Dữ liệu mẫu'),
('HN004_K01', 'SEED_CUSTOMER', 'TB_4H',    '2026-11-06 18:00', '2026-11-06 22:00', 326000, 'CONFIRMED', NULL,     0,     N'Dữ liệu mẫu');

-- 9. Một đánh giá mẫu (cho booking phòng HN001_Q01 ở trên)
INSERT INTO Review (BookingId, RoomId, UserId, Rating, Comment)
SELECT BookingId, RoomId, UserId, 5, N'Phòng sạch, màn chiếu nét, sẽ quay lại.'
FROM Booking
WHERE UserId = 'SEED_CUSTOMER' AND RoomId = 'HN001_Q01';

-- 10. Một thông báo mẫu (cho booking đã được xác nhận ở trên)
INSERT INTO Notification (UserId, BookingId, Title, Message)
SELECT UserId, BookingId, N'Đặt phòng đã được xác nhận', N'Staff đã xác nhận booking của bạn. Hẹn gặp bạn!'
FROM Booking
WHERE UserId = 'SEED_CUSTOMER' AND Status = 'CONFIRMED';
GO
