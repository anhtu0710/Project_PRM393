// lib/providers/notification_provider.dart

import 'dart:async';
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
  Timer? _pollTimer;

  NotificationListNotifier(this._service) : super(const NotificationListState()) {
    // Đăng ký theo dõi trạng thái App (Foreground / Background)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed) {
      if (_currentUserId != null) {
        _silentReload(_currentUserId!);
        _startPolling(_currentUserId!);
      }
    } else if (appState == AppLifecycleState.paused) {
      _pollTimer?.cancel();
    }
  }

  void _startPolling(String userId) {
    _pollTimer?.cancel();
    // Polling tự động kiểm tra thông báo mới mỗi 6 giây
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_currentUserId != null && _currentUserId == userId) {
        _silentReload(userId);
      }
    });
  }

  Future<void> loadNotifications(String userId) async {
    _currentUserId = userId;
    _startPolling(userId);
    
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
    _pollTimer?.cancel();
    _pollTimer = null;
    state = const NotificationListState();
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final notificationListProvider = StateNotifierProvider<NotificationListNotifier,
    NotificationListState>((ref) {
  return NotificationListNotifier(ref.read(notificationServiceProvider));
});
