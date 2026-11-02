// lib/screens/staff/staff_booking_screen.dart
// Phụ trách: TV4

import 'package:flutter/material.dart';

class StaffBookingScreen extends StatelessWidget {
  const StaffBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: const Center(
        child: Text('TV4 làm: danh sách booking, duyệt / từ chối, check-in, check-out'),
      ),
    );
  }
}
