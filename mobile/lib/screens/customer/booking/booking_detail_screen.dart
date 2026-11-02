// lib/screens/customer/booking/booking_detail_screen.dart
// Phụ trách: TV3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_config.dart';
import '../../../config/app_theme.dart';
import '../../../models/booking_model.dart';
import '../../../providers/booking_provider.dart';
import '../../../services/booking_service.dart';
import 'booking_ui.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final int bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _cancelling = false;

  // Giống điều kiện ở backend: chỉ huỷ khi chưa nhận phòng
  bool _canCancel(BookingModel b) =>
      b.status == AppConfig.bookingPending ||
      b.status == AppConfig.bookingConfirmed;

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ booking?'),
        content: const Text('Bạn chắc chắn muốn huỷ đặt phòng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Huỷ booking',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(bookingServiceProvider).cancelBooking(widget.bookingId);
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã huỷ booking')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(BookingService.errorMessage(e, 'Huỷ booking thất bại')),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncBooking = ref.watch(bookingDetailProvider(widget.bookingId));

    return Scaffold(
      appBar: AppBar(title: Text('Booking #${widget.bookingId}')),
      body: asyncBooking.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Không tải được booking',
                  style: TextStyle(color: AppTheme.textGray)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(bookingDetailProvider(widget.bookingId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (b) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section(
              child: Row(
                children: [
                  RoomThumbnail(imageUrl: b.roomImageUrl, size: 72),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.roomName ?? b.roomId,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        if (b.hotelName != null)
                          Text(b.hotelName!,
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.textPrimary)),
                        if (b.hotelAddress != null)
                          Text(b.hotelAddress!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textGray)),
                        const SizedBox(height: 8),
                        StatusChip(status: b.status),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _section(
              child: Column(
                children: [
                  _row('Hình thức', b.typeBookingName ?? b.typeBookingId),
                  _row('Nhận phòng',
                      '${formatTime(b.checkIn)}  ${formatDate(b.checkIn)}'),
                  if (b.checkOut != null)
                    _row('Trả phòng',
                        '${formatTime(b.checkOut!)}  ${formatDate(b.checkOut!)}'),
                  if (b.note != null && b.note!.isNotEmpty)
                    _row('Lời nhắn', b.note!),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _section(
              child: Column(
                children: [
                  _row('Tiền phòng',
                      formatVND((b.totalPrice ?? 0) + (b.discountAmount ?? 0))),
                  _row(
                    b.voucherCode != null
                        ? 'Voucher (${b.voucherCode})'
                        : 'Voucher',
                    (b.discountAmount ?? 0) > 0
                        ? '– ${formatVND(b.discountAmount!)}'
                        : '0 đ',
                  ),
                  const Divider(color: Color(0xFFEDE7FF)),
                  _row('Tổng thanh toán', formatVND(b.totalPrice ?? 0),
                      bold: true),
                ],
              ),
            ),
            if (_canCancel(b)) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _cancelling ? null : _cancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _cancelling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Huỷ booking',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section({required Widget child}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDE7FF)),
        ),
        child: child,
      );

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: bold ? AppTheme.textPrimary : AppTheme.textGray,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: bold ? 16 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: bold ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
}
