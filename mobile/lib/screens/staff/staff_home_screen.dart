// lib/screens/staff/staff_home_screen.dart
// Trang đầu của Staff: danh sách nút đi tới từng màn hình

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class StaffHomeScreen extends ConsumerWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.book_online),
            title: const Text('Booking, duyệt, check-in / check-out'),
            onTap: () => context.push('/staff/bookings'),
          ),
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('Sơ đồ phòng'),
            onTap: () => context.push('/staff/room-map'),
          ),
          ListTile(
            leading: const Icon(Icons.meeting_room),
            title: const Text('Quản lý phòng'),
            onTap: () => context.push('/staff/rooms'),
          ),
          ListTile(
            leading: const Icon(Icons.price_change),
            title: const Text('Bảng giá'),
            onTap: () => context.push('/staff/prices'),
          ),
          ListTile(
            leading: const Icon(Icons.local_offer),
            title: const Text('Voucher'),
            onTap: () => context.push('/staff/vouchers'),
          ),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Chi nhánh'),
            onTap: () => context.push('/staff/hotels'),
          ),
        ],
      ),
    );
  }
}
