// lib/config/app_config.dart

class AppConfig {
  // ── Database ────────────────────────────────────────────────────
  // Bản này KHÔNG dùng server: dữ liệu nằm trong SQLite ngay trên điện thoại
  // (xem lib/database/database_helper.dart và seed_data.dart).

  // ── Lưu người đang đăng nhập ──────────────────────────────────────────────────────────────
  static const String tokenKey    = 'jwt_token';
  static const String userKey     = 'current_user';

  // ── Roles (must match RoleName in DB) ────────────────────────────────
  static const String roleAdmin           = 'ADMIN';
  static const String roleStaff           = 'STAFF';
  static const String roleCustomer        = 'CUSTOMER';

  // ── Role IDs (must match roleId in Role table) ────────────────────────
  static const String roleCustomerId      = 'CUSTOMER';

  // ── Trạng thái booking (giống BookingStatus.java) ─────────────────────
  static const String bookingPending   = 'PENDING';    // Chờ duyệt
  static const String bookingConfirmed = 'CONFIRMED';  // Đã xác nhận
  static const String bookingRejected  = 'REJECTED';   // Bị từ chối
  static const String bookingCheckedIn = 'CHECKED_IN'; // Đang ở
  static const String bookingCompleted = 'COMPLETED';  // Hoàn thành
  static const String bookingCancelled = 'CANCELLED';  // Đã huỷ

  // ── Trạng thái phòng (giống RoomStatus.java) ──────────────────────────
  static const String roomAvailable = 'Trống';
  static const String roomOccupied  = 'Đang dùng';
  static const String roomCleaning  = 'Đang dọn';

  // ── App ───────────────────────────────────────────────────────────────
  static const String appName = 'GenzCinema Hotel';
}