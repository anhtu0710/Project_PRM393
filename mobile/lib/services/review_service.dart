// lib/services/review_service.dart
// Đánh giá sau lưu trú — đọc ghi bảng Review trong SQLite

import '../database/database_helper.dart';
import '../models/review_eligible_booking_model.dart';
import '../models/room_model.dart';
import 'auth_service.dart';

class ReviewService {
  /// Lấy userId của người đang đăng nhập
  Future<String> _currentUserId() async {
    final user = await AuthService().getCurrentUser();
    if (user == null) throw 'Vui lòng đăng nhập';
    return user.userId;
  }

  /// Các booking đã hoàn thành, đã trả phòng và chưa được đánh giá
  Future<List<ReviewEligibleBookingModel>> getEligibleBookings() async {
    final userId = await _currentUserId();
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT b.BookingId, b.RoomId, b.checkOut, r.nameRoom, h.name AS hotelName
      FROM Booking b
      LEFT JOIN Room r ON b.RoomId = r.RoomId
      LEFT JOIN Hotel h ON r.HotelId = h.HotelId
      WHERE b.UserId = ? AND b.Status = 'COMPLETED'
        AND b.BookingId NOT IN (SELECT BookingId FROM Review)
      ORDER BY b.checkOut DESC''', [userId]);

    final now = DateTime.now();
    final result = <ReviewEligibleBookingModel>[];
    for (final row in rows) {
      final checkOut = DateTime.tryParse(row['checkOut'] as String? ?? '');
      if (checkOut == null || checkOut.isAfter(now)) continue; // chưa trả phòng
      result.add(ReviewEligibleBookingModel(
        bookingId: row['BookingId'] as int,
        roomId: row['RoomId'] as String,
        roomName: row['nameRoom'] as String? ?? 'Phòng',
        hotelName: row['hotelName'] as String? ?? '',
        checkOut: checkOut,
      ));
    }
    return result;
  }

  Future<ReviewModel> createReview({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    final userId = await _currentUserId();
    final db = await DatabaseHelper.database;

    final bookings = await db.query('Booking', where: 'BookingId = ?', whereArgs: [bookingId]);
    if (bookings.isEmpty) throw 'Không tìm thấy booking';
    final booking = bookings.first;

    if (booking['UserId'] != userId) {
      throw 'Bạn chỉ có thể đánh giá booking của mình';
    }
    final checkOut = DateTime.tryParse(booking['checkOut'] as String? ?? '');
    if (booking['Status'] != 'COMPLETED' ||
        checkOut == null ||
        checkOut.isAfter(DateTime.now())) {
      throw 'Chỉ có thể đánh giá sau khi đã check-out';
    }
    final existed = await db.query('Review', where: 'BookingId = ?', whereArgs: [bookingId]);
    if (existed.isNotEmpty) throw 'Booking này đã được đánh giá';

    final cleanComment =
        (comment == null || comment.trim().isEmpty) ? null : comment.trim();
    final now = DateTime.now();
    final reviewId = await db.insert('Review', {
      'BookingId': bookingId,
      'RoomId': booking['RoomId'],
      'UserId': userId,
      'Rating': rating,
      'Comment': cleanComment,
      'CreatedAt': now.toIso8601String(),
    });

    final users = await db.query('[User]', where: 'UserId = ?', whereArgs: [userId]);
    return ReviewModel(
      reviewId: reviewId,
      bookingId: bookingId,
      rating: rating,
      comment: cleanComment,
      reviewerName: users.first['full_name'] as String? ?? 'Khách hàng',
      createdAt: now,
    );
  }
}
