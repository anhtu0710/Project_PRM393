// lib/screens/notification/notification_screen.dart
// Phụ trách: TV4

import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: const Center(
        child: Text('TV4 làm: danh sách thông báo của khách'),
      ),
    );
  }
}
