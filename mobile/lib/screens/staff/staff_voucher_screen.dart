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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(isEdit ? 'Sửa Voucher' : 'Thêm Voucher'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Mã Voucher (VD: GENZ10)'),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('%'),
                          value: true,
                          groupValue: isPercent,
                          onChanged: (val) => setModalState(() => isPercent = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Số tiền'),
                          value: false,
                          groupValue: isPercent,
                          onChanged: (val) => setModalState(() => isPercent = val!),
                        ),
                      ),
                    ],
                  ),
                  if (isPercent)
                    TextField(
                      controller: percentController,
                      decoration: const InputDecoration(labelText: 'Phần trăm giảm (%)'),
                      keyboardType: TextInputType.number,
                    )
                  else
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Số tiền giảm (VNĐ)'),
                      keyboardType: TextInputType.number,
                    ),
                  TextField(
                    controller: minOrderController,
                    decoration: const InputDecoration(labelText: 'Đơn hàng tối thiểu (VNĐ)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: expiryController,
                    decoration: const InputDecoration(labelText: 'Hạn dùng (YYYY-MM-DD)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
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
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? (isEdit ? 'Đã cập nhật Voucher' : 'Đã thêm Voucher')
                            : 'Có lỗi xảy ra'),
                      ),
                    );
                  }
                },
                child: Text(isEdit ? 'Lưu' : 'Thêm'),
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
