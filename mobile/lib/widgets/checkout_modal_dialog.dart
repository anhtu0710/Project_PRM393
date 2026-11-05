// lib/widgets/checkout_modal_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/booking_model.dart';
import '../models/food_menu_model.dart';
import '../providers/booking_provider.dart';
import '../providers/food_provider.dart';
import '../providers/room_provider.dart';
import '../screens/customer/booking/booking_ui.dart';
import '../services/booking_service.dart';
import 'app_image.dart';

class CheckoutModalDialog extends ConsumerStatefulWidget {
  final BookingModel booking;

  const CheckoutModalDialog({super.key, required this.booking});

  static Future<bool?> show(BuildContext context, BookingModel booking) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckoutModalDialog(booking: booking),
    );
  }

  @override
  ConsumerState<CheckoutModalDialog> createState() => _CheckoutModalDialogState();
}

class _CheckoutModalDialogState extends ConsumerState<CheckoutModalDialog> {
  final Map<int, int> _selectedFnbQuantities = {}; // FoodId -> Quantity
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final foodState = ref.watch(foodMenuListProvider);

    // 1. Tính toán Phụ thu Trễ giờ
    final now = DateTime.now();
    final scheduledCheckOut = b.checkOut ?? now;
    final lateMinutes = now.difference(scheduledCheckOut).inMinutes;

    int lateHours = 0;
    if (lateMinutes > 15) {
      lateHours = ((lateMinutes - 15) ~/ 60) + 1;
    }

    // Giá giờ mặc định theo loại phòng (King / Football / Gaming = 106k/h, Queen/Box khác = 96k/h)
    double pricePerHour = 96000;
    if (b.roomId.contains('K') || b.roomId.contains('GM') || b.roomId.contains('FB')) {
      pricePerHour = 106000;
    }
    final lateFee = lateHours * pricePerHour;

    // 2. Tính toán Tiền Order Menu F&B
    double fnbTotal = 0.0;
    final Map<FoodMenuModel, int> selectedItems = {};
    for (final food in foodState.items) {
      final qty = _selectedFnbQuantities[food.foodId] ?? 0;
      if (qty > 0) {
        fnbTotal += food.price * qty;
        selectedItems[food] = qty;
      }
    }

    // 3. Tính Tổng Thanh Toán Sau Cùng
    final originalPrice = b.totalPrice ?? 0.0;
    final finalTotal = originalPrice + lateFee + fnbTotal;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),

          // Header Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: AppTheme.primary, size: 26),
                const SizedBox(width: 10),
                Text(
                  'Thanh Toán Check-out #${b.bookingId ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
          const Divider(),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin phòng & thời gian
                  _buildSectionCard(
                    title: 'Thông Tin Phòng',
                    icon: Icons.meeting_room_outlined,
                    child: Column(
                      children: [
                        _infoRow('Tên phòng', b.roomName ?? b.roomId),
                        _infoRow('Khách hàng', b.userFullName ?? b.userId),
                        _infoRow('Giờ hẹn trả', '${formatTime(scheduledCheckOut)} ${formatDate(scheduledCheckOut)}'),
                        _infoRow('Giờ trả thực tế', '${formatTime(now)} ${formatDate(now)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Phần 1: Phụ Thu Trễ Giờ
                  _buildSectionCard(
                    title: '1. Phụ Thu Ra Muộn (Late Checkout)',
                    icon: Icons.timer_outlined,
                    iconColor: Colors.orange.shade700,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (lateMinutes <= 15) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    lateMinutes > 0
                                        ? 'Trễ $lateMinutes phút (Dưới 15 phút - Miễn phí phụ thu)'
                                        : 'Đúng giờ / Trả phòng sớm - Không phụ thu',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDBA74)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEA580C),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Quá giờ $lateMinutes phút',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFC2410C),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Quá 15p tính thành $lateHours giờ x ${formatVND(pricePerHour)}/h',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF9A3412)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                _infoRow('Số giờ phụ thu', '$lateHours giờ'),
                                const Divider(height: 10, color: Color(0xFFE2E8F0)),
                                _infoRow('Đơn giá niêm yết', '${formatVND(pricePerHour)} / giờ'),
                                const Divider(height: 10, color: Color(0xFFE2E8F0)),
                                _infoRow('Phụ thu trễ giờ', formatVND(lateFee), isHighlight: true, color: const Color(0xFFDC2626)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Phần 2: Order Đồ Ăn F&B Phát Sinh
                  _buildSectionCard(
                    title: '2. Order Đồ Ăn & Thức Uống F&B Phát Sinh',
                    icon: Icons.restaurant_outlined,
                    iconColor: AppTheme.primary,
                    child: Column(
                      children: [
                        if (foodState.isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (foodState.items.isEmpty)
                          const Text('Không có thực đơn F&B', style: TextStyle(color: AppTheme.textGray))
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: foodState.items.length,
                            separatorBuilder: (_, __) => const Divider(height: 12),
                            itemBuilder: (context, index) {
                              final item = foodState.items[index];
                              final qty = _selectedFnbQuantities[item.foodId] ?? 0;

                              return Row(
                                children: [
                                  AppImage(
                                    imageUrl: item.imageUrl,
                                    width: 42,
                                    height: 42,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        Text(formatVND(item.price), style: const TextStyle(fontSize: 11, color: AppTheme.textGray)),
                                      ],
                                    ),
                                  ),
                                  // Quantity Counter
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppTheme.cardBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        InkWell(
                                          onTap: qty > 0
                                              ? () {
                                                  setState(() {
                                                    _selectedFnbQuantities[item.foodId] = qty - 1;
                                                  });
                                                }
                                              : null,
                                          borderRadius: BorderRadius.circular(20),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(Icons.remove, size: 16, color: AppTheme.textPrimary),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            '$qty',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: qty > 0 ? AppTheme.primary : AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedFnbQuantities[item.foodId] = qty + 1;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(20),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(Icons.add, size: 16, color: AppTheme.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phần 3: Bảng Tổng Hợp Hóa Đơn Thanh Toán
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        _summaryRow('Tiền phòng gốc', formatVND(originalPrice)),
                        if (lateFee > 0)
                          _summaryRow('Phụ thu trễ giờ ($lateHours h)', '+ ${formatVND(lateFee)}', color: AppTheme.error),
                        if (fnbTotal > 0)
                          _summaryRow('Menu F&B phát sinh', '+ ${formatVND(fnbTotal)}', color: AppTheme.primary),
                        const Divider(color: AppTheme.primary, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TỔNG THANH TOÁN',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            Text(
                              formatVND(finalTotal),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_rounded, color: Colors.white),
                      label: Text(
                        _isSubmitting ? 'Đang xử lý...' : 'Xác nhận Check-out & Thanh toán',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              final bookingId = b.bookingId;
                              if (bookingId == null) return;

                              setState(() => _isSubmitting = true);
                              try {
                                // Tạo chuỗi ghi chú hóa đơn chi tiết
                                final StringBuffer noteBuffer = StringBuffer();
                                if (b.note != null && b.note!.isNotEmpty) {
                                  noteBuffer.write('${b.note} | ');
                                }
                                noteBuffer.write('Check-out: ${formatVND(finalTotal)}');
                                if (lateHours > 0) {
                                  noteBuffer.write(' (Trễ $lateHours h: +${formatVND(lateFee)})');
                                }
                                if (selectedItems.isNotEmpty) {
                                  noteBuffer.write(' (F&B: ');
                                  final itemStrings = selectedItems.entries
                                      .map((e) => '${e.key.name} x${e.value}')
                                      .join(', ');
                                  noteBuffer.write('$itemStrings)');
                                }

                                await ref.read(bookingServiceProvider).updateBookingStatus(
                                      bookingId,
                                      AppConfig.bookingCompleted,
                                      totalPrice: finalTotal,
                                      note: noteBuffer.toString(),
                                    );

                                // Refresh Riverpod Providers
                                ref.invalidate(bookingDetailProvider(bookingId));
                                ref.invalidate(myBookingsProvider);
                                ref.read(roomListProvider.notifier).loadRooms();

                                if (!mounted) return;
                                Navigator.pop(context, true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã Check-out & Thanh toán thành công ${formatVND(finalTotal)}!'),
                                    backgroundColor: AppTheme.primary,
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(BookingService.errorMessage(e, 'Thanh toán thất bại')),
                                    backgroundColor: AppTheme.error,
                                  ),
                                );
                              } finally {
                                if (mounted) setState(() => _isSubmitting = false);
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child, IconData? icon, Color? iconColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: iconColor ?? AppTheme.primary),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isHighlight = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: boldText(value),
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  FontWeight boldText(String value) {
    return value.contains('+') ? FontWeight.bold : FontWeight.w600;
  }
}
