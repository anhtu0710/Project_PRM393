// lib/providers/notification_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

final notificationServiceProvider =
    Provider<NotificationService>((_) => NotificationService());

class NotificationListState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  const NotificationListState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.read).length;

  NotificationListState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationListState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationListNotifier extends StateNotifier<NotificationListState> {
  final NotificationService _service;

  NotificationListNotifier(this._service) : super(const NotificationListState());

  Future<void> loadNotifications(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _service.getNotifications(userId);
      // Sắp xếp thông báo mới nhất đứng đầu
      list.sort((a, b) {
        final idA = a.notificationId ?? 0;
        final idB = b.notificationId ?? 0;
        return idB.compareTo(idA);
      });
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tải danh sách thông báo',
      );
    }
  }

  Future<void> markAsRead(int notificationId, String userId) async {
    await _service.markAsRead(notificationId);
    await loadNotifications(userId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _service.markAllAsRead(userId);
    await loadNotifications(userId);
  }

  Future<void> deleteNotification(int notificationId, String userId) async {
    await _service.deleteNotification(notificationId);
    await loadNotifications(userId);
  }
}

final notificationListProvider = StateNotifierProvider<NotificationListNotifier,
    NotificationListState>((ref) {
  return NotificationListNotifier(ref.read(notificationServiceProvider));
});
