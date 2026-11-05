// lib/providers/notification_provider.dart

import 'package:flutter/widgets.dart';
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

class NotificationListNotifier extends StateNotifier<NotificationListState> with WidgetsBindingObserver {
  final NotificationService _service;
  String? _currentUserId;

  NotificationListNotifier(this._service) : super(const NotificationListState()) {
    // Đăng ký theo dõi trạng thái App (Foreground / Background)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    // Khi người dùng mở app lên lại từ màn hình chính hoặc sau khi khóa màn hình
    if (appState == AppLifecycleState.resumed) {
      if (_currentUserId != null) {
        _silentReload(_currentUserId!);
      }
    }
  }

  Future<void> loadNotifications(String userId) async {
    _currentUserId = userId;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _service.getNotifications(userId);
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

  // Tải lại ngầm không làm hiển thị loading
  Future<void> _silentReload(String userId) async {
    try {
      final list = await _service.getNotifications(userId);
      list.sort((a, b) {
        final idA = a.notificationId ?? 0;
        final idB = b.notificationId ?? 0;
        return idB.compareTo(idA);
      });
      if (_hasChanges(state.notifications, list)) {
        state = state.copyWith(notifications: list);
      }
    } catch (e) {
      // Bỏ qua lỗi
    }
  }

  bool _hasChanges(List<NotificationModel> oldList, List<NotificationModel> newList) {
    if (oldList.length != newList.length) return true;
    for (int i = 0; i < oldList.length; i++) {
      if (oldList[i].notificationId != newList[i].notificationId ||
          oldList[i].read != newList[i].read) {
        return true;
      }
    }
    return false;
  }

  Future<void> markAsRead(int notificationId, String userId) async {
    await _service.markAsRead(notificationId);
    await _silentReload(userId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _service.markAllAsRead(userId);
    await _silentReload(userId);
  }

  Future<void> deleteNotification(int notificationId, String userId) async {
    await _service.deleteNotification(notificationId);
    await _silentReload(userId);
  }

  void clear() {
    _currentUserId = null;
    state = const NotificationListState();
  }
  
  @override
  void dispose() {
    // Hủy đăng ký khi provider bị hủy
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final notificationListProvider = StateNotifierProvider<NotificationListNotifier,
    NotificationListState>((ref) {
  return NotificationListNotifier(ref.read(notificationServiceProvider));
});
