// lib/screens/customer/booking/booking_ui.dart
// Widget + hàm định dạng dùng chung cho màn lịch sử và chi tiết booking.

import 'package:flutter/material.dart';
import '../../../config/app_config.dart';
import '../../../config/app_theme.dart';
import '../../../widgets/app_image.dart';

/// 276000 -> "276.000 đ"
String formatVND(double amount) {
  final n = amount.toInt().toString();
  final buf = StringBuffer();
  for (int i = 0; i < n.length; i++) {
    if (i > 0 && (n.length - i) % 3 == 0) buf.write('.');
    buf.write(n[i]);
  }
  return '${buf.toString()} đ';
}

String _two(int v) => v.toString().padLeft(2, '0');

String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

String formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// "01/11/2026 19:00 – 21:00" (hoặc kèm ngày ra nếu khác ngày)
String formatTimeRange(DateTime checkIn, DateTime? checkOut) {
  final start = '${formatDate(checkIn)} ${formatTime(checkIn)}';
  if (checkOut == null) return start;
  final sameDay = checkIn.year == checkOut.year &&
      checkIn.month == checkOut.month &&
      checkIn.day == checkOut.day;
  final end = sameDay
      ? formatTime(checkOut)
      : '${formatDate(checkOut)} ${formatTime(checkOut)}';
  return '$start – $end';
}

/// Tên tiếng Việt + màu cho từng trạng thái booking
(String, Color) statusInfo(String? status) {
  switch (status) {
    case AppConfig.bookingPending:
      return ('Chờ duyệt', Colors.orange);
    case AppConfig.bookingConfirmed:
      return ('Đã xác nhận', Colors.blue);
    case AppConfig.bookingCheckedIn:
      return ('Đang ở', AppTheme.primary);
    case AppConfig.bookingCompleted:
      return ('Hoàn thành', AppTheme.success);
    case AppConfig.bookingRejected:
      return ('Bị từ chối', AppTheme.error);
    case AppConfig.bookingCancelled:
      return ('Đã huỷ', AppTheme.textGray);
    default:
      return (status ?? '—', AppTheme.textGray);
  }
}

class StatusChip extends StatelessWidget {
  final String? status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = statusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class RoomThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const RoomThumbnail({super.key, required this.imageUrl, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return AppImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
    );
  }
}
