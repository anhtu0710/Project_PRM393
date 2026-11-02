// lib/screens/admin/admin_user_screen.dart
// Phụ trách: TV1

import 'package:flutter/material.dart';

class AdminUserScreen extends StatelessWidget {
  const AdminUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý người dùng')),
      body: const Center(
        child: Text('TV1 làm: danh sách user, đổi role, khoá / mở khoá'),
      ),
    );
  }
}
