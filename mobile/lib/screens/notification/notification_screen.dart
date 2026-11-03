// lib/screens/notification/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  bool _onlyUnread = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(notificationListProvider.notifier).loadNotifications(user.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final notifState = ref.watch(notificationListProvider);

    final userId = user?.userId ?? '';

    final filteredList = _onlyUnread
        ? notifState.notifications.where((n) => !n.read).toList()
        : notifState.notifications;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Trung Tâm Thông Báo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (notifState.unreadCount > 0)
            TextButton(
              onPressed: () {
                if (userId.isNotEmpty) {
                  ref.read(notificationListProvider.notifier).markAllAsRead(userId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã đánh dấu tất cả thông báo là đã đọc!'),
                      backgroundColor: AppTheme.primary,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('Tất cả (${notifState.notifications.length})', !_onlyUnread, () {
                  setState(() => _onlyUnread = false);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Chưa đọc (${notifState.unreadCount})', _onlyUnread, () {
                  setState(() => _onlyUnread = true);
                }),
              ],
            ),
          ),

          // Main List
          Expanded(
            child: notifState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  )
                : user == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('Vui lòng đăng nhập để xem thông báo', style: TextStyle(color: AppTheme.textGray)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => context.push('/login'),
                              child: const Text('Đăng nhập'),
                            ),
                          ],
                        ),
                      )
                    : filteredList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  _onlyUnread ? 'Không có thông báo chưa đọc nào' : 'Bạn chưa có thông báo nào',
                                  style: const TextStyle(color: AppTheme.textGray),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              await ref.read(notificationListProvider.notifier).loadNotifications(userId);
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                return _buildNotificationCard(context, filteredList[index], userId);
                              },
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notif, String userId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notif.read ? Colors.white : const Color(0xFFFAF5FF), // Soft purple highlight for unread
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notif.read ? AppTheme.cardBorder : AppTheme.primary.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: notif.read
                ? const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFF64748B)])
                : AppTheme.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notif.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: notif.read ? FontWeight.w600 : FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (!notif.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 6),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notif.message,
              style: const TextStyle(fontSize: 12, color: AppTheme.textGray, height: 1.3),
            ),
            if (notif.createdAt != null) ...[
              const SizedBox(height: 6),
              Text(
                _formatDate(notif.createdAt!),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey.shade400),
          onPressed: () {
            if (notif.notificationId != null) {
              ref.read(notificationListProvider.notifier).deleteNotification(notif.notificationId!, userId);
            }
          },
        ),
        onTap: () {
          if (!notif.read && notif.notificationId != null) {
            ref.read(notificationListProvider.notifier).markAsRead(notif.notificationId!, userId);
          }
          if (notif.bookingId != null) {
            context.push('/bookings/${notif.bookingId}');
          }
        },
      ),
    );
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')} - ${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }
}
