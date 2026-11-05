// lib/services/booking_service.dart

import 'package:dio/dio.dart';
import '../models/booking_model.dart';
import 'api_client.dart';

class BookingService {
  final Dio _dio = ApiClient.instance.dio;

  /// Lấy câu báo lỗi tiếng Việt từ ApiResponse của backend (nếu có)
  static String errorMessage(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }
    return fallback;
  }

  /// Tạo booking mới (server tự tính giá, giờ ra, voucher)
  Future<BookingModel> createBooking(BookingModel booking) async {
    final response = await _dio.post('/bookings', data: booking.toJson());
    return BookingModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Lấy danh sách booking theo userId
  Future<List<BookingModel>> getBookingsByUser(String userId) async {
    final response = await _dio.get('/bookings/user/$userId');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lấy tất cả booking (Staff / Admin)
  Future<List<BookingModel>> getAllBookings() async {
    final response = await _dio.get('/bookings');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cập nhật trạng thái booking (Duyệt, Từ chối, Check-in, Check-out + Tính tổng tiền)
  Future<BookingModel> updateBookingStatus(int id, String status, {double? totalPrice, String? note}) async {
    final response = await _dio.put(
      '/bookings/$id/status',
      queryParameters: {
        'status': status,
        if (totalPrice != null) 'totalPrice': totalPrice,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return BookingModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Lấy chi tiết 1 booking
  Future<BookingModel> getBookingById(int id) async {
    final response = await _dio.get('/bookings/$id');
    return BookingModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Khách huỷ booking
  Future<BookingModel> cancelBooking(int id) async {
    final response = await _dio.put('/bookings/$id/cancel');
    return BookingModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Danh sách voucher còn hạn
  Future<List<VoucherModel>> getVouchers() async {
    final response = await _dio.get('/bookings/vouchers');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => VoucherModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Kiểm tra mã voucher với tổng tiền. Sai thì ném DioException (400 + message).
  Future<VoucherModel> checkVoucher(String code, double amount) async {
    final response = await _dio.get('/bookings/vouchers/check',
        queryParameters: {'code': code, 'amount': amount});
    return VoucherModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Bảng giá: map "TYPEROOM|TYPEBOOKING" -> giá
  Future<Map<String, double>> getPrices() async {
    final response = await _dio.get('/bookings/prices');
    final data = response.data['data'] as List<dynamic>;
    final result = <String, double>{};
    for (final e in data) {
      final m = e as Map<String, dynamic>;
      final typeRoomId =
          (m['typeRoom'] as Map<String, dynamic>?)?['typeRoomId'] as String?;
      final typeBookingId = (m['typeBooking']
          as Map<String, dynamic>?)?['typeBookingId'] as String?;
      final price = (m['price'] as num?)?.toDouble();
      if (typeRoomId != null && typeBookingId != null && price != null) {
        result['${typeRoomId.toUpperCase()}|$typeBookingId'] = price;
      }
    }
    return result;
  }

  /// Lấy danh sách gói thuê (TypeBooking) động từ server
  Future<List<TypeBookingModel>> getTypeBookings() async {
    final response = await _dio.get('/type-bookings');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => TypeBookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
