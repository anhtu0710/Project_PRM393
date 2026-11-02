// lib/screens/staff/staff_voucher_screen.dart
// Phụ trách: TV5

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/voucher_model.dart';
import '../../providers/voucher_provider.dart';

class StaffVoucherScreen extends ConsumerStatefulWidget {
  const StaffVoucherScreen({super.key});

  @override
  ConsumerState<StaffVoucherScreen> createState() => _StaffVoucherScreenState();
}

class _StaffVoucherScreenState extends ConsumerState<StaffVoucherScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voucherListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Voucher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(voucherListProvider.notifier).loadVouchers(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.vouchers.isEmpty
              ? const Center(child: Text('Chưa có voucher nào'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.vouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = state.vouchers[index];
                    final isPercent = voucher.discountPercent != null;
                    final discountText = isPercent
                        ? 'Giảm ${voucher.discountPercent!.toInt()}%'
                        : 'Giảm ${voucher.discountAmount?.toInt() ?? 0}đ';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber.shade100,
                          child: const Icon(Icons.confirmation_number, color: Colors.amber),
                        ),
                        title: Text(
                          voucher.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.deepOrange,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(discountText, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (voucher.description != null) Text(voucher.description!),
                            Text('Đơn tối thiểu: ${voucher.minOrderAmount.toInt()}đ'),
                            Text('HSD: ${voucher.expiryDate.split("T").first}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showVoucherDialog(voucher: voucher),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(voucher.voucherId!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVoucherDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF4B5563)),
    );
  }

  void _showVoucherDialog({VoucherModel? voucher}) {
    final isEdit = voucher != null;
    final codeController = TextEditingController(text: voucher?.code ?? '');
    final descController = TextEditingController(text: voucher?.description ?? '');
    final percentController = TextEditingController(
        text: voucher?.discountPercent != null ? voucher!.discountPercent.toString() : '');
    final amountController = TextEditingController(
        text: voucher?.discountAmount != null ? voucher!.discountAmount.toString() : '');
    final minOrderController = TextEditingController(
        text: voucher?.minOrderAmount != null ? voucher!.minOrderAmount.toString() : '0');
    final expiryController = TextEditingController(
        text: voucher?.expiryDate != null ? voucher!.expiryDate.split("T").first : '2027-12-31');

    bool isPercent = voucher?.discountPercent != null || voucher?.discountAmount == null;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_note : Icons.confirmation_number,
                  color: const Color(0xFF9462FF),
                ),
                const SizedBox(width: 10),
                Text(
                  isEdit ? 'Sửa Voucher' : 'Thêm Voucher mới',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Mã Voucher'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: codeController,
                        decoration: InputDecoration(
                          hintText: 'VD: GENZ10',
                          prefixIcon: const Icon(Icons.tag, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFieldLabel('Mô tả Voucher'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: descController,
                        decoration: InputDecoration(
                          hintText: 'Mô tả ngắn...',
                          prefixIcon: const Icon(Icons.description, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFieldLabel('Hình thức giảm giá'),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('% Phần trăm'),
                              icon: Icon(Icons.percent, size: 18),
                            ),
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('Số tiền (VNĐ)'),
                              icon: Icon(Icons.attach_money, size: 18),
                            ),
                          ],
                          selected: {isPercent},
                          onSelectionChanged: (set) => setModalState(() => isPercent = set.first),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isPercent) ...[
                        _buildFieldLabel('Phần trăm giảm (%)'),
                        const SizedBox(height: 4),
                        TextField(
                          controller: percentController,
                          decoration: InputDecoration(
                            hintText: 'VD: 10',
                            prefixIcon: const Icon(Icons.discount, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ] else ...[
                        _buildFieldLabel('Số tiền giảm (VNĐ)'),
                        const SizedBox(height: 4),
                        TextField(
                          controller: amountController,
                          decoration: InputDecoration(
                            hintText: 'VD: 50000',
                            prefixIcon: const Icon(Icons.payments, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildFieldLabel('Đơn hàng tối thiểu (VNĐ)'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: minOrderController,
                        decoration: InputDecoration(
                          hintText: 'VD: 0 hoặc 200000',
                          prefixIcon: const Icon(Icons.shopping_bag, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildFieldLabel('Hạn sử dụng'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: expiryController,
                        readOnly: true,
                        onTap: () async {
                          final initial = DateTime.tryParse(expiryController.text) ?? DateTime(2027, 12, 31);
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setModalState(() {
                              expiryController.text =
                                  "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            });
                          }
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.calendar_month, size: 20),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9462FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  final newVoucher = VoucherModel(
                    voucherId: voucher?.voucherId,
                    code: codeController.text.trim(),
                    description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                    discountPercent: isPercent && percentController.text.isNotEmpty
                        ? double.tryParse(percentController.text.trim())
                        : null,
                    discountAmount: !isPercent && amountController.text.isNotEmpty
                        ? double.tryParse(amountController.text.trim())
                        : null,
                    minOrderAmount: double.tryParse(minOrderController.text.trim()) ?? 0,
                    expiryDate: '${expiryController.text.trim()}T23:59:59',
                  );

                  final notifier = ref.read(voucherListProvider.notifier);
                  final success = isEdit
                      ? await notifier.updateVoucher(voucher.voucherId!, newVoucher)
                      : await notifier.createVoucher(newVoucher);

                  if (mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? (isEdit ? 'Đã cập nhật Voucher' : 'Đã thêm Voucher')
                            : 'Có lỗi xảy ra'),
                      ),
                    );
                  }
                },
                child: Text(isEdit ? 'Lưu' : 'Thêm', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa voucher này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await ref.read(voucherListProvider.notifier).deleteVoucher(id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Đã xóa voucher' : 'Xóa thất bại'),
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
