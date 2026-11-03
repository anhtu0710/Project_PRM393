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
      final user = ref.read(authProvider).user;
      if (user == null) {
        context.push('/login');
      } else {
        context.push('/profile');
      }
      return;
    }
    if (index == currentIndex) return;
    final routes = ['/home', '/saved', '/rooms'];
    context.push(routes[index]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.06),
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
