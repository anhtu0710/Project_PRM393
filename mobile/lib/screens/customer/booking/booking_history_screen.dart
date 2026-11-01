// lib/screens/customer/booking/booking_history_screen.dart
// Phụ trách: TV3

import 'package:flutter/material.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử đặt phòng')),
      body: const Center(
        child: Text('TV3 làm: 3 tab Sắp tới / Đã qua / Đã huỷ'),
      ),
    );
  }
}
