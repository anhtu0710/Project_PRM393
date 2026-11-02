// lib/screens/customer/booking/booking_history_screen.dart
// Phụ trách: TV3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_config.dart';
import '../../../config/app_theme.dart';
import '../../../models/booking_model.dart';
import '../../../providers/booking_provider.dart';
import 'booking_ui.dart';

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  // Sắp tới: chờ duyệt, đã xác nhận, đang ở
  static bool _isUpcoming(BookingModel b) =>
      b.status == AppConfig.bookingPending ||
      b.status == AppConfig.bookingConfirmed ||
      b.status == AppConfig.bookingCheckedIn;

  // Đã huỷ: khách huỷ hoặc bị từ chối
  static bool _isCancelled(BookingModel b) =>
      b.status == AppConfig.bookingCancelled ||
      b.status == AppConfig.bookingRejected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBookings = ref.watch(myBookingsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử đặt phòng'),
          bottom: const TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textGray,
            indicatorColor: AppTheme.primary,
            tabs: [
              Tab(text: 'Sắp tới'),
              Tab(text: 'Đã qua'),
              Tab(text: 'Đã huỷ'),
            ],
          ),
        ),
        body: asyncBookings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            onRetry: () => ref.invalidate(myBookingsProvider),
          ),
          data: (all) {
            final upcoming = all.where(_isUpcoming).toList()
              // Sắp tới: gần nhất lên đầu
              ..sort((a, b) => a.checkIn.compareTo(b.checkIn));
            final cancelled = all.where(_isCancelled).toList();
            final past = all
                .where((b) => !_isUpcoming(b) && !_isCancelled(b))
                .toList();

            return TabBarView(
              children: [
                _BookingList(
                    bookings: upcoming, emptyText: 'Chưa có booking sắp tới'),
                _BookingList(
                    bookings: past, emptyText: 'Chưa có booking đã qua'),
                _BookingList(
                    bookings: cancelled, emptyText: 'Không có booking bị huỷ'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookingList extends ConsumerWidget {
  final List<BookingModel> bookings;
  final String emptyText;

  const _BookingList({required this.bookings, required this.emptyText});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> refresh() async {
      ref.invalidate(myBookingsProvider);
      await ref.read(myBookingsProvider.future);
    }

    if (bookings.isEmpty) {
      // Vẫn cho kéo để tải lại khi danh sách trống
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.event_note_outlined,
                size: 56, color: AppTheme.textGray),
            const SizedBox(height: 12),
            Text(emptyText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textGray)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = booking;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await context.push('/bookings/${b.bookingId}');
          // Quay lại từ màn chi tiết (có thể đã huỷ) thì tải lại danh sách
          ref.invalidate(myBookingsProvider);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDE7FF)),
          ),
          child: Row(
            children: [
              RoomThumbnail(imageUrl: b.roomImageUrl, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            b.roomName ?? b.roomId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary),
                          ),
                        ),
                        StatusChip(status: b.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.hotelName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textGray),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatTimeRange(b.checkIn, b.checkOut),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatVND(b.totalPrice ?? 0),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Không tải được lịch sử đặt phòng',
              style: TextStyle(color: AppTheme.textGray)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
