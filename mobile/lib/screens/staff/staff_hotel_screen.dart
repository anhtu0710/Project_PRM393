// lib/screens/staff/staff_hotel_screen.dart
// Phụ trách: TV5

import 'package:flutter/material.dart';

class StaffHotelScreen extends StatelessWidget {
  const StaffHotelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi nhánh')),
      body: const Center(
        child: Text('TV5 làm: thêm, sửa chi nhánh'),
      ),
    );
  }
}
