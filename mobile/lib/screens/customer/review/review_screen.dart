import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/app_theme.dart';
import '../../../models/review_eligible_booking_model.dart';
import '../../../services/review_service.dart';

class EligibleReviewsScreen extends StatefulWidget {
  const EligibleReviewsScreen({super.key});

  @override
  State<EligibleReviewsScreen> createState() => _EligibleReviewsScreenState();
}

class _EligibleReviewsScreenState extends State<EligibleReviewsScreen> {
  final ReviewService _service = ReviewService();
  late Future<List<ReviewEligibleBookingModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getEligibleBookings();
  }

  void _reload() => setState(() => _future = _service.getEligibleBookings());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá sau lưu trú'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<List<ReviewEligibleBookingModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.error_outline,
              message: 'Không thể tải các lượt lưu trú.',
              actionLabel: 'Thử lại',
              onAction: _reload,
            );
          }
          final bookings = snapshot.data ?? const [];
          if (bookings.isEmpty) {
            return const _MessageState(
              icon: Icons.rate_review_outlined,
              message: 'Bạn chưa có lượt lưu trú nào cần đánh giá.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final booking = bookings[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFEDE7FF)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF1E7FF),
                      child:
                          Icon(Icons.movie_outlined, color: AppTheme.primary),
                    ),
                    title: Text(booking.roomName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(booking.hotelName),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppTheme.primary),
                    onTap: () async {
                      final submitted = await context.push<bool>(
                        '/reviews/${booking.bookingId}',
                        extra: booking,
                      );
                      if (submitted == true && mounted) _reload();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ReviewFormScreen extends StatefulWidget {
  final ReviewEligibleBookingModel booking;
  const ReviewFormScreen({super.key, required this.booking});

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final ReviewService _service = ReviewService();
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn số sao đánh giá.')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _service.createReview(
        bookingId: widget.booking.bookingId,
        rating: _rating,
        comment: _commentController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')));
        context.pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Không thể gửi đánh giá. Vui lòng thử lại.')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá phòng'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.booking.roomName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              if (widget.booking.hotelName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(widget.booking.hotelName,
                    style: const TextStyle(color: AppTheme.textGray)),
              ],
              const SizedBox(height: 32),
              const Text('Trải nghiệm của bạn thế nào?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                    5,
                    (index) => IconButton(
                          onPressed: () => setState(() => _rating = index + 1),
                          icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: const Color(0xFFFFC107),
                              size: 36),
                        )),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _commentController,
                maxLines: 5,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: 'Chia sẻ thêm nhận xét của bạn (không bắt buộc)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Gửi đánh giá'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _MessageState(
      {required this.icon,
      required this.message,
      this.actionLabel,
      this.onAction});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppTheme.textGray)),
          if (onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ]),
      );
}
