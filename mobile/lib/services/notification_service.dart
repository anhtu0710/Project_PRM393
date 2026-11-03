// lib/services/notification_service.dart

import 'package:dio/dio.dart';
import '../models/notification_model.dart';
import 'api_client.dart';

class NotificationService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final response = await _dio.get('/notifications/user/$userId');
      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'] as List<dynamic>;
        return data
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      await _dio.put('/notifications/$notificationId/read');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead(String userId) async {
    try {
      await _dio.put('/notifications/user/$userId/read-all');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      await _dio.delete('/notifications/$notificationId');
      return true;
    } catch (e) {
      return false;
    }
  }
}
