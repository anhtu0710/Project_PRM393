// lib/screens/staff/staff_voucher_screen.dart
// Phụ trách: TV5

import 'package:flutter/material.dart';

class StaffVoucherScreen extends StatelessWidget {
  const StaffVoucherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voucher')),
      body: const Center(
        child: Text('TV5 làm: tạo, sửa, xoá voucher'),
      ),
    );
  }
}
