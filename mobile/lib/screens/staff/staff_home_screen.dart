// lib/screens/staff/staff_home_screen.dart
// Phụ trách: Trang chủ Nhân viên (Staff Dashboard)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/room_provider.dart';

class StaffHomeScreen extends ConsumerWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final roomState = ref.watch(roomListProvider);
    final notifState = ref.watch(notificationListProvider);
    final unreadCount = notifState.unreadCount;

    // Tính toán số liệu tổng quan từ Database
    final totalRooms = roomState.rooms.length;
    final availableRooms = roomState.rooms.where((r) {
      final s = r.status?.toLowerCase() ?? '';
      return s == 'trống' || s == 'available';
    }).length;

    final occupiedRooms = roomState.rooms.where((r) {
      final s = r.status?.toLowerCase() ?? '';
      return s == 'đang dùng' || s == 'đang ở' || s == 'occupied';
    }).length;

    final cleaningRooms = roomState.rooms.where((r) {
      final s = r.status?.toLowerCase() ?? '';
      return s == 'đang dọn' || s == 'cleaning';
    }).length;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              errorBuilder: (_, __, ___) => const Text(
                'GenZ Cinema',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'STAFF HUB',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.primary, size: 26),
                tooltip: 'Thông báo vận hành',
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: AppTheme.primary),
            tooltip: 'Hồ sơ cá nhân',
            onPressed: () => context.push('/staff/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
            tooltip: 'Đăng xuất',
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Staff Profile Header Banner ──────────────────────────────────
            InkWell(
              onTap: () => context.push('/staff/profile'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            authState.user?.fullName.isNotEmpty == true
                                ? authState.user!.fullName.substring(0, 1).toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppTheme.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, ${authState.user?.fullName ?? "Staff GenZ"} 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Trung Tâm Vận Hành GenZ Cinema',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Realtime Room Overview Bar ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildStatPill('Tổng phòng', '$totalRooms', AppTheme.primary, Icons.king_bed_outlined),
                  _buildStatDivider(),
                  _buildStatPill('Phòng Trống', '$availableRooms', AppTheme.success, Icons.check_circle_outline),
                  _buildStatDivider(),
                  _buildStatPill('Đang Dùng', '$occupiedRooms', AppTheme.error, Icons.meeting_room_outlined),
                  _buildStatDivider(),
                  _buildStatPill('Đang Dọn', '$cleaningRooms', AppTheme.goldAccent, Icons.cleaning_services_outlined),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Phần 1: Vận hành phòng & Khách hàng (3 items: 2 top + 1 full-width bottom) ──
            _buildSectionTitle('VẬN HÀNH PHÒNG & KHÁCH HÀNG'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: 'Duyệt Booking',
                    subtitle: 'Duyệt & Check-in / Out',
                    icon: Icons.bookmark_added_rounded,
                    gradient: AppTheme.primaryGradient,
                    onTap: () => context.push('/staff/bookings'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: 'Sơ Đồ Phòng',
                    subtitle: 'Sơ đồ Realtime & Danh sách',
                    icon: Icons.grid_view_rounded,
                    gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                    onTap: () => context.push('/staff/room-map'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildWideMenuCard(
              context,
              title: 'Quản Lý Chi Nhánh',
              subtitle: 'Danh sách và thông tin 9 cơ sở GenZ Cinema',
              icon: Icons.storefront_rounded,
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
              onTap: () => context.push('/staff/hotels'),
            ),
            const SizedBox(height: 24),

            // ── Phần 2: Cấu hình bảng giá & Dịch vụ (4 items: 2x2 grid) ───────
            _buildSectionTitle('CẤU HÌNH BẢNG GIÁ & DỊCH VỤ'),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.32,
              ),
              itemBuilder: (context, index) {
                final items = [
                  {
                    'title': 'Quản Lý Phim Hot',
                    'subtitle': 'Thêm, sửa, xóa phim chiếu',
                    'icon': Icons.movie_rounded,
                    'gradient': const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                    'route': '/staff/movies',
                  },
                  {
                    'title': 'Quản Lý F&B Menu',
                    'subtitle': 'Đồ ăn & Thức uống',
                    'icon': Icons.restaurant_menu_rounded,
                    'gradient': const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                    'route': '/staff/food',
                  },
                  {
                    'title': 'Bảng Giá Gói Thuê',
                    'subtitle': 'Cấu hình giá Combo',
                    'icon': Icons.sell_rounded,
                    'gradient': AppTheme.goldGradient,
                    'route': '/staff/prices',
                  },
                  {
                    'title': 'Voucher Khuyến Mãi',
                    'subtitle': 'Mã giảm giá hệ thống',
                    'icon': Icons.confirmation_number_rounded,
                    'gradient': const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFBE185D)]),
                    'route': '/staff/vouchers',
                  },
                ];
                final item = items[index];
                return _buildMenuCard(
                  context,
                  title: item['title'] as String,
                  subtitle: item['subtitle'] as String,
                  icon: item['icon'] as IconData,
                  gradient: item['gradient'] as LinearGradient,
                  onTap: () => context.push(item['route'] as String),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textGray,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textGray, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppTheme.cardBorder,
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Nhân viên không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy', style: TextStyle(color: AppTheme.textGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
