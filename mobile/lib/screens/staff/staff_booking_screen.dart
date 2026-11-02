// lib/screens/staff/staff_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';

class StaffBookingScreen extends ConsumerWidget {
  const StaffBookingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(staffBookingsProvider);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Duyệt & Vận hành Booking'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(staffBookingsProvider),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Chờ duyệt'),
              Tab(text: 'Đã xác nhận'),
              Tab(text: 'Đã Check-in'),
              Tab(text: 'Đã xong'),
              Tab(text: 'Đã hủy / Từ chối'),
            ],
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
            final pendingList = bookings
                .where((b) => b.status?.toUpperCase() == AppConfig.bookingPending)
                .toList();
            final confirmedList = bookings
                .where((b) => b.status?.toUpperCase() == AppConfig.bookingConfirmed)
                .toList();
            final checkedInList = bookings
                .where((b) => b.status?.toUpperCase() == AppConfig.bookingCheckedIn)
                .toList();
            final completedList = bookings
                .where((b) => b.status?.toUpperCase() == AppConfig.bookingCompleted)
                .toList();
            final cancelledList = bookings
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

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(child: Text('Không có booking nào'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        final statusColor = _statusColor(b.status);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Booking #${b.bookingId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        _statusText(b.status),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Text('Phòng: ${b.roomId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Khách đặt: ${b.userFullName ?? b.userId} (${b.userPhone ?? "Không SĐT"})'),
                Text('Nhận phòng: ${b.formattedCheckIn}'),
                Text('Trả phòng: ${b.formattedCheckOut}'),
                if (b.note != null && b.note!.isNotEmpty)
                  Text('Ghi chú: ${b.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 6),
                Text(
                  'Tổng tiền: ${b.totalPrice?.toInt() ?? 0} VNĐ',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
                const SizedBox(height: 10),
                _buildActionButtons(context, b),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, BookingModel b) {
    final status = b.status?.toUpperCase();

    if (status == AppConfig.bookingPending) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Duyệt', style: TextStyle(color: Colors.white)),
              onPressed: () => _updateStatus(context, b.bookingId!, AppConfig.bookingConfirmed),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              icon: const Icon(Icons.close),
              label: const Text('Từ chối'),
              onPressed: () => _updateStatus(context, b.bookingId!, AppConfig.bookingRejected),
            ),
          ),
        ],
      );
    }

    if (status == AppConfig.bookingConfirmed) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text('Check-in', style: TextStyle(color: Colors.white)),
              onPressed: () => _updateStatus(context, b.bookingId!, AppConfig.bookingCheckedIn),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              icon: const Icon(Icons.cancel),
              label: const Text('Hủy'),
              onPressed: () => _updateStatus(context, b.bookingId!, AppConfig.bookingCancelled),
            ),
          ),
        ],
      );
    }

    if (status == AppConfig.bookingCheckedIn) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text('Check-out (Thu tiền)', style: TextStyle(color: Colors.white)),
          onPressed: () => _updateStatus(context, b.bookingId!, AppConfig.bookingCompleted),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _updateStatus(BuildContext context, int bookingId, String newStatus) async {
    try {
      await ref.read(bookingServiceProvider).updateBookingStatus(bookingId, newStatus);
      ref.invalidate(staffBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật trạng thái booking thành công')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra: $e')),
        );
      }
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case AppConfig.bookingPending:
        return Colors.orange;
      case AppConfig.bookingConfirmed:
        return Colors.blue;
      case AppConfig.bookingCheckedIn:
        return Colors.purple;
      case AppConfig.bookingCompleted:
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  String _statusText(String? status) {
    switch (status?.toUpperCase()) {
      case AppConfig.bookingPending:
        return 'Chờ duyệt';
      case AppConfig.bookingConfirmed:
        return 'Đã xác nhận';
      case AppConfig.bookingCheckedIn:
        return 'Đã Check-in';
      case AppConfig.bookingCompleted:
        return 'Hoàn thành';
      case AppConfig.bookingRejected:
        return 'Bị từ chối';
      case AppConfig.bookingCancelled:
        return 'Đã hủy';
      default:
        return status ?? 'Khác';
    }
  }
}
