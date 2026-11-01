// lib/screens/staff/staff_room_map_screen.dart
// Phụ trách: TV4

import 'package:flutter/material.dart';

class StaffRoomMapScreen extends StatelessWidget {
  const StaffRoomMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sơ đồ phòng')),
      body: const Center(
        child: Text('TV4 làm: lưới phòng, màu theo Trống / Đang dùng / Đang dọn'),
      ),
    );
  }
}
