// lib/screens/staff/staff_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/checkout_modal_dialog.dart';

class StaffBookingScreen extends ConsumerStatefulWidget {
  const StaffBookingScreen({super.key});

  @override
  ConsumerState<StaffBookingScreen> createState() => _StaffBookingScreenState();
}

class _StaffBookingScreenState extends ConsumerState<StaffBookingScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(staffBookingsProvider);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: const Text('Duyệt & Vận hành Booking'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(staffBookingsProvider),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(105),
            child: Column(
              children: [
                // Thanh Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm theo SĐT khách, tên phòng, mã đơn...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ),
                const TabBar(
                  isScrollable: true,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textGray,
                  indicatorColor: AppTheme.primary,
                  tabs: [
                    Tab(text: 'Chờ duyệt'),
                    Tab(text: 'Đã xác nhận'),
                    Tab(text: 'Đã Check-in'),
                    Tab(text: 'Đã xong'),
                    Tab(text: 'Đã hủy / Từ chối'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lỗi: $err', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(staffBookingsProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
          data: (bookings) {
            final filtered = bookings.where((b) {
              if (_searchQuery.isEmpty) return true;
              final q = _searchQuery;
              final phone = (b.userPhone ?? '').toLowerCase();
              final room = b.roomId.toLowerCase();
              final id = b.bookingId?.toString() ?? '';
              final name = (b.userFullName ?? '').toLowerCase();
              return phone.contains(q) || room.contains(q) || id.contains(q) || name.contains(q);
            }).toList();

            final pendingList = filtered
                .where((b) => b.status?.toUpperCase() == AppConfig.bookingPending)
                .toList();
            final confirmedList = filtered
                .where((b) => b.status?.toUpperCase() == AppConfig.bookingConfirmed)
                .toList();
            final checkedInList = filtered
                .where((b) => b.status?.toUpperCase() == AppConfig.bookingCheckedIn)
                .toList();
            final completedList = filtered
                .where((b) => b.status?.toUpperCase() == AppConfig.bookingCompleted)
                .toList();
            final cancelledList = filtered
                .where((b) =>
                    b.status?.toUpperCase() == AppConfig.bookingCancelled ||
                    b.status?.toUpperCase() == AppConfig.bookingRejected)
                .toList();

            return TabBarView(
              children: [
                _BookingListView(bookings: pendingList, ref: ref),
                _BookingListView(bookings: confirmedList, ref: ref),
                _BookingListView(bookings: checkedInList, ref: ref),
                _BookingListView(bookings: completedList, ref: ref),
                _BookingListView(bookings: cancelledList, ref: ref),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookingListView extends StatelessWidget {
  final List<BookingModel> bookings;
  final WidgetRef ref;

  const _BookingListView({required this.bookings, required this.ref});

  Color _statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case AppConfig.bookingPending:
        return Colors.orange;
      case AppConfig.bookingConfirmed:
        return Colors.blue;
      case AppConfig.bookingCheckedIn:
        return AppTheme.primary;
      case AppConfig.bookingCompleted:
        return AppTheme.success;
      case AppConfig.bookingCancelled:
      case AppConfig.bookingRejected:
        return AppTheme.error;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String? status) {
    switch (status?.toUpperCase()) {
      case AppConfig.bookingPending:
        return 'Chờ duyệt';
      case AppConfig.bookingConfirmed:
        return 'Đã xác nhận';
      case AppConfig.bookingCheckedIn:
        return 'Đang ở (Check-in)';
      case AppConfig.bookingCompleted:
        return 'Hoàn thành';
      case AppConfig.bookingCancelled:
        return 'Đã hủy';
      case AppConfig.bookingRejected:
        return 'Bị từ chối';
      default:
        return status ?? '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Text('Không có đơn đặt phòng nào', style: TextStyle(color: AppTheme.textGray)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        final statusColor = _statusColor(b.status);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mã đơn #${b.bookingId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        _statusText(b.status),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.meeting_room_outlined, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text('Phòng: ${b.roomId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppTheme.textGray),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Khách: ${b.userFullName ?? b.userId} (${b.userPhone ?? "Không SĐT"})',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textGray),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Thời gian: ${b.formattedCheckIn} – ${b.formattedCheckOut}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                      ),
                    ),
                  ],
                ),
                if (b.note != null && b.note!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.note_outlined, size: 16, color: AppTheme.textGray),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ghi chú: ${b.note}',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textGray),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng: ${b.totalPrice?.toInt() ?? 0} VNĐ',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                    _buildActionButtons(context, b, ref),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, BookingModel b, WidgetRef ref) {
    final status = b.status?.toUpperCase() ?? '';

    if (status == AppConfig.bookingPending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => _updateStatus(context, b.bookingId!, AppConfig.bookingRejected, ref),
            child: const Text('Từ chối', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => _updateStatus(context, b.bookingId!, AppConfig.bookingConfirmed, ref),
            child: const Text('Xác nhận', style: TextStyle(fontSize: 12, color: Colors.white)),
          ),
        ],
      );
    }

    if (status == AppConfig.bookingConfirmed) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        icon: const Icon(Icons.login_rounded, size: 16, color: Colors.white),
        label: const Text('Check-in', style: TextStyle(fontSize: 12, color: Colors.white)),
        onPressed: () => _updateStatus(context, b.bookingId!, AppConfig.bookingCheckedIn, ref),
      );
    }

    if (status == AppConfig.bookingCheckedIn) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.success,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16, color: Colors.white),
        label: const Text('Checkout & F&B', style: TextStyle(fontSize: 12, color: Colors.white)),
        onPressed: () => _showCheckoutDialog(context, b),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _updateStatus(BuildContext context, int id, String newStatus, WidgetRef ref) async {
    try {
      await ref.read(bookingServiceProvider).updateBookingStatus(id, newStatus);
      ref.invalidate(staffBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái đơn thành công')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thất bại: $e')),
        );
      }
    }
  }

  void _showCheckoutDialog(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (ctx) => CheckoutModalDialog(booking: booking),
    );
  }
}
