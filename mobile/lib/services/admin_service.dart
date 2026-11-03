// lib/services/admin_service.dart
// Admin: quản lý tài khoản + thống kê — đọc ghi SQLite.
// Luật giống AdminController.java và StatsService.java bên Spring Boot.

import '../config/app_config.dart';
import '../database/database_helper.dart';
import '../models/admin_stats_model.dart';
import '../models/admin_user_model.dart';

class AdminService {
  /// Lấy câu báo lỗi tiếng Việt (service ném lỗi dạng String)
  static String errorMessage(Object e, String fallback) {
    if (e is String) return e;
    return fallback;
  }

  /// Danh sách tất cả tài khoản
  Future<List<AdminUserModel>> getUsers() async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT u.*, r.RoleName FROM [User] u
      LEFT JOIN Role r ON u.RoleId = r.RoleId''');
    return rows
        .map((r) => AdminUserModel(
              userId: r['UserId'] as String,
              fullName: r['full_name'] as String? ?? '',
              email: r['email'] as String? ?? '',
              phone: r['phone'] as String? ?? '',
              roleId: r['RoleId'] as String? ?? '',
              roleName: r['RoleName'] as String? ?? '',
              locked: r['IsLocked'] == 1,
            ))
        .toList();
  }

  /// Đọc RoleId của 1 tài khoản, không có thì báo lỗi
  Future<String?> _roleOf(String userId) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query('[User]', where: 'UserId = ?', whereArgs: [userId]);
    if (rows.isEmpty) throw 'Không tìm thấy người dùng';
    return rows.first['RoleId'] as String?;
  }

  /// Đổi role: roleId là 'CUSTOMER' hoặc 'STAFF'
  Future<void> changeRole(String userId, String roleId) async {
    if (await _roleOf(userId) == AppConfig.roleAdmin) {
      throw 'Không thể đổi role của tài khoản Admin';
    }
    if (roleId != AppConfig.roleCustomer && roleId != AppConfig.roleStaff) {
      throw 'Chỉ đổi được giữa CUSTOMER và STAFF';
    }
    final db = await DatabaseHelper.database;
    await db.update('[User]', {'RoleId': roleId},
        where: 'UserId = ?', whereArgs: [userId]);
  }

  /// Khoá (locked = true) hoặc mở khoá (locked = false)
  Future<void> setLocked(String userId, bool locked) async {
    if (await _roleOf(userId) == AppConfig.roleAdmin) {
      throw 'Không thể khoá tài khoản Admin';
    }
    final db = await DatabaseHelper.database;
    await db.update('[User]', {'IsLocked': locked ? 1 : 0},
        where: 'UserId = ?', whereArgs: [userId]);
  }

  /// Thống kê: period là 'day' (7 ngày), 'week' (8 tuần) hoặc 'month' (6 tháng).
  /// Booking thuộc cột nào là tính theo ngày nhận phòng (checkIn).
  Future<AdminStatsModel> getStats(String period) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeEnd = today.add(const Duration(days: 1)); // tính đến hết hôm nay

    // 1. Chia khoảng thời gian thành các cột của biểu đồ
    final columnStarts = <DateTime>[]; // ngày bắt đầu của từng cột
    final labels = <String>[];
    if (period == 'month') {
      for (int i = 5; i >= 0; i--) {
        final start = DateTime(today.year, today.month - i, 1);
        columnStarts.add(start);
        labels.add('T${start.month}');
      }
    } else if (period == 'week') {
      final monday = today.subtract(Duration(days: today.weekday - 1));
      for (int i = 7; i >= 0; i--) {
        final start = monday.subtract(Duration(days: 7 * i));
        columnStarts.add(start);
        labels.add('${start.day}/${start.month}');
      }
    } else {
      for (int i = 6; i >= 0; i--) {
        final start = today.subtract(Duration(days: i));
        columnStarts.add(start);
        labels.add('${start.day}/${start.month}');
      }
    }
    final rangeStart = columnStarts.first;

    // 2. Chuẩn bị chỗ cộng dồn
    final revenueByColumn = List<double>.filled(columnStarts.length, 0);
    double totalRevenue = 0;
    int totalBookings = 0;
    double soldHours = 0; // tổng số giờ phòng đã bán

    // Giữ đúng thứ tự 6 trạng thái để app hiện đẹp
    final statusCounts = <String, int>{
      AppConfig.bookingPending: 0,
      AppConfig.bookingConfirmed: 0,
      AppConfig.bookingCheckedIn: 0,
      AppConfig.bookingCompleted: 0,
      AppConfig.bookingCancelled: 0,
      AppConfig.bookingRejected: 0,
    };
    final countByRoom = <String, int>{}; // roomId -> số lượt đặt

    // 3. Duyệt toàn bộ booking 1 lần
    final db = await DatabaseHelper.database;
    final bookings = await db.query('Booking');
    for (final b in bookings) {
      final checkIn = DateTime.parse(b['checkIn'] as String);
      final day = DateTime(checkIn.year, checkIn.month, checkIn.day);
      if (day.isBefore(rangeStart) || !day.isBefore(rangeEnd)) continue; // ngoài khoảng

      final status = b['Status'] as String? ?? '';
      totalBookings++;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      // Doanh thu: chỉ booking đã hoàn thành
      final price = (b['totalPrice'] as num?)?.toDouble();
      if (status == AppConfig.bookingCompleted && price != null) {
        final column = _findColumn(columnStarts, day);
        revenueByColumn[column] += price;
        totalRevenue += price;
      }

      // Giờ đã bán: booking đã xác nhận, đang ở hoặc đã xong
      if ((status == AppConfig.bookingConfirmed ||
              status == AppConfig.bookingCheckedIn ||
              status == AppConfig.bookingCompleted) &&
          b['checkOut'] != null) {
        final checkOut = DateTime.parse(b['checkOut'] as String);
        soldHours += checkOut.difference(checkIn).inMinutes / 60.0;
      }

      // Phòng được đặt nhiều: bỏ qua booking đã huỷ / bị từ chối
      if (status != AppConfig.bookingCancelled &&
          status != AppConfig.bookingRejected) {
        final roomId = b['RoomId'] as String;
        countByRoom[roomId] = (countByRoom[roomId] ?? 0) + 1;
      }
    }

    // 4. Tỉ lệ lấp phòng = giờ đã bán / (số phòng × số giờ trong khoảng)
    final roomCount = (await db.rawQuery('SELECT COUNT(*) AS total FROM Room'))
        .first['total'] as int;
    final userCount = (await db.rawQuery('SELECT COUNT(*) AS total FROM [User]'))
        .first['total'] as int;
    final hoursInRange = rangeEnd.difference(rangeStart).inHours;
    double occupancyRate = 0;
    if (roomCount > 0 && hoursInRange > 0) {
      occupancyRate = soldHours * 100 / (roomCount * hoursInRange);
      occupancyRate = (occupancyRate * 10).round() / 10; // làm tròn 1 chữ số
    }

    // 5. Biểu đồ doanh thu
    final chart = <ChartPointModel>[];
    for (int i = 0; i < columnStarts.length; i++) {
      chart.add(ChartPointModel(label: labels[i], revenue: revenueByColumn[i]));
    }

    // 6. Top 5 phòng
    final topRooms = <TopRoomModel>[];
    for (final roomId in countByRoom.keys) {
      final rows = await db.rawQuery('''
        SELECT r.nameRoom, h.name FROM Room r
        LEFT JOIN Hotel h ON r.HotelId = h.HotelId
        WHERE r.RoomId = ?''', [roomId]);
      topRooms.add(TopRoomModel(
        roomId: roomId,
        roomName: rows.isEmpty ? roomId : rows.first['nameRoom'] as String? ?? '',
        hotelName: rows.isEmpty ? '' : rows.first['name'] as String? ?? '',
        bookingCount: countByRoom[roomId]!,
      ));
    }
    topRooms.sort((a, b) => b.bookingCount - a.bookingCount); // nhiều nhất lên đầu

    // 7. Gói kết quả
    return AdminStatsModel(
      totalRevenue: totalRevenue,
      totalBookings: totalBookings,
      occupancyRate: occupancyRate,
      totalRooms: roomCount,
      totalUsers: userCount,
      revenueChart: chart,
      statusCounts: statusCounts,
      topRooms: topRooms.take(5).toList(),
    );
  }

  // Booking ngày "day" rơi vào cột nào (cột cuối cùng có ngày bắt đầu <= day)
  int _findColumn(List<DateTime> columnStarts, DateTime day) {
    for (int i = columnStarts.length - 1; i >= 0; i--) {
      if (!day.isBefore(columnStarts[i])) return i;
    }
    return 0;
  }
}
