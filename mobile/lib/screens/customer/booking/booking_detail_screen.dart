// lib/screens/customer/booking/booking_detail_screen.dart
// Phụ trách: TV3

import 'package:flutter/material.dart';

class BookingDetailScreen extends StatelessWidget {
  final int bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Booking #$bookingId')),
      body: const Center(
        child: Text('TV3 làm: chi tiết booking và nút huỷ'),
      ),
    );
  }
}
