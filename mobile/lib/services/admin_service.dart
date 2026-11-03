// lib/services/admin_service.dart
// Gọi các API của Admin: /admin/users, /admin/stats

import 'package:dio/dio.dart';
import '../models/admin_stats_model.dart';
import '../models/admin_user_model.dart';
import 'api_client.dart';

class AdminService {
  final Dio _dio = ApiClient.instance.dio;

  /// Lấy câu báo lỗi tiếng Việt từ backend (nếu có)
  static String errorMessage(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }
    return fallback;
  }

  /// Danh sách tất cả tài khoản
  Future<List<AdminUserModel>> getUsers() async {
    final response = await _dio.get('/admin/users');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Đổi role: roleId là 'CUSTOMER' hoặc 'STAFF'
  Future<void> changeRole(String userId, String roleId) async {
    await _dio.put('/admin/users/$userId/role',
        queryParameters: {'roleId': roleId});
  }

  /// Gán chi nhánh phụ trách cho Staff (hotelId = 'HN001'...)
  Future<void> assignHotel(String userId, String? hotelId) async {
    await _dio.put('/admin/users/$userId/hotel',
        queryParameters: {
          if (hotelId != null && hotelId.isNotEmpty) 'hotelId': hotelId,
        });
  }

  /// Khoá (locked = true) hoặc mở khoá (locked = false)
  Future<void> setLocked(String userId, bool locked) async {
    await _dio.put('/admin/users/$userId/lock',
        queryParameters: {'locked': locked});
  }

  /// Thống kê: period là 'day', 'week' hoặc 'month'
  Future<AdminStatsModel> getStats(String period) async {
    final response =
        await _dio.get('/admin/stats', queryParameters: {'period': period});
    return AdminStatsModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}
