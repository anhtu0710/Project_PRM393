// lib/widgets/app_bottom_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

class AppBottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const AppBottomNavBar({super.key, required this.currentIndex});

  static const _items = [
    {
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home_rounded,
      'label': 'Trang chủ'
    },
    {
      'icon': Icons.bookmark_border_rounded,
      'activeIcon': Icons.bookmark_rounded,
      'label': 'Đã lưu'
    },
    {
      'icon': Icons.king_bed_outlined,
      'activeIcon': Icons.king_bed_rounded,
      'label': 'Đặt chỗ'
    },
    {
      'icon': Icons.person_outline_rounded,
      'activeIcon': Icons.person_rounded,
      'label': 'Tài khoản'
    },
  ];

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    if (index == 3) {
      _showAccountSheet(context, ref);
      return;
    }
    if (index == currentIndex) return;
    final routes = ['/home', '/saved', '/rooms'];
    context.go(routes[index]);
  }

  void _showAccountSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    final bool isLoggedIn = user != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              if (isLoggedIn)
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    if (GoRouterState.of(context).matchedLocation != '/profile') {
                      context.push('/profile');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                          child: ShaderMask(
                            shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                            child: const Icon(Icons.person, color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                user.email,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              const Divider(),
              if (!isLoggedIn)
                ListTile(
                  leading: const Icon(Icons.login_rounded, color: AppTheme.primary),
                  title: const Text('Đăng nhập / Đăng ký', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/login');
                  },
                )
              else ...[
                ListTile(
                  leading: const Icon(Icons.rate_review_outlined, color: AppTheme.primary),
                  title: const Text('Đánh giá sau lưu trú', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/reviews');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history_rounded, color: AppTheme.primary),
                  title: const Text('Lịch sử đặt phòng', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/bookings');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded, color: AppTheme.primary),
                  title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/notifications');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppTheme.primaryDark),
                  title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(_items.length, (index) {
              final bool isSelected = index == currentIndex;
              final item = _items[index];

              return Expanded(
                child: InkWell(
                  onTap: () => _onTap(context, ref, index),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AppTheme.primaryGradient.createShader(bounds),
                            child: Icon(item['activeIcon'] as IconData,
                                color: Colors.white, size: 24),
                          )
                        else
                          Icon(item['icon'] as IconData,
                              color: AppTheme.textGray, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primary : AppTheme.textGray,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
