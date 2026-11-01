// lib/screens/staff/staff_price_screen.dart
// Phụ trách: TV5

import 'package:flutter/material.dart';

class StaffPriceScreen extends StatelessWidget {
  const StaffPriceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bảng giá')),
      body: const Center(
        child: Text('TV5 làm: sửa giá theo loại phòng và combo'),
      ),
    );
  }
}
