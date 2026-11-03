// lib/screens/customer/voucher/voucher_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../models/voucher_model.dart';
import '../../../providers/voucher_provider.dart';
import '../../../widgets/app_bottom_nav_bar.dart';

class VoucherListScreen extends ConsumerStatefulWidget {
  const VoucherListScreen({super.key});

  @override
  ConsumerState<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends ConsumerState<VoucherListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voucherListProvider.notifier).loadVouchers();
    });
  }

  String _formatVND(double amount) {
    return '${(amount / 1000).toStringAsFixed(0)}k';
  }

  void _copyToClipboard(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã "$code" vào bộ nhớ tạm!'),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voucherState = ref.watch(voucherListProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Voucher & Khuyến Mãi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: voucherState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            )
          : voucherState.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('Không thể tải danh sách Voucher', style: TextStyle(color: AppTheme.textGray)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(voucherListProvider.notifier).loadVouchers(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : voucherState.vouchers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('Hiện không có Voucher khuyến mãi nào', style: TextStyle(color: AppTheme.textGray)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: voucherState.vouchers.length,
                      itemBuilder: (context, index) {
                        return _buildVoucherCard(context, voucherState.vouchers[index]);
                      },
                    ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildVoucherCard(BuildContext context, VoucherModel v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left gradient stub
            Container(
              width: 100,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 32),
                  const SizedBox(height: 6),
                  Text(
                    v.code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Dashed Divider Line
            CustomPaint(
              size: const Size(1, double.infinity),
              painter: _DashedLinePainter(),
            ),
            // Right info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      v.description ?? 'Ưu đãi đặt phòng GenZ Cinema',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      v.discountPercent != null
                          ? 'Giảm ${v.discountPercent}% cho tất cả đơn hàng'
                          : 'Giảm ${_formatVND(v.discountAmount ?? 0)} cho đơn từ ${_formatVND(v.minOrderAmount)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'HSD: ${_formatDate(v.expiryDate)}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textGray),
                        ),
                        OutlinedButton(
                          onPressed: () => _copyToClipboard(context, v.code),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Sao chép', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return 'Hạn dùng vĩnh viễn';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.cardBorder
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
