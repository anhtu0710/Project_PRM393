// lib/screens/staff/staff_room_manage_screen.dart
// Phụ trách: TV5

import 'package:flutter/material.dart';

class StaffRoomManageScreen extends StatelessWidget {
  const StaffRoomManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý phòng')),
      body: const Center(
        child: Text('TV5 làm: thêm, sửa, xoá phòng'),
      ),
    );
  }
}
