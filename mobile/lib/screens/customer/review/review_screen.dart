// lib/screens/customer/review/review_screen.dart
// Phụ trách: TV2

import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  final int bookingId;

  const ReviewScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá phòng')),
      body: Center(
        child: Text('TV2 làm: chấm 1–5 sao cho booking #$bookingId'),
      ),
    );
  }
}
