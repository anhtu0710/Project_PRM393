// lib/screens/staff/staff_price_screen.dart
// Phụ trách: TV5

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/price_config_model.dart';
import '../../models/room_model.dart';
import '../../providers/price_config_provider.dart';

class StaffPriceScreen extends ConsumerStatefulWidget {
  const StaffPriceScreen({super.key});

  @override
  ConsumerState<StaffPriceScreen> createState() => _StaffPriceScreenState();
}

class _StaffPriceScreenState extends ConsumerState<StaffPriceScreen> {
  String? selectedTypeRoomId;

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF4B5563)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(priceConfigListProvider);

    final filteredConfigs = selectedTypeRoomId == null
        ? state.configs
        : state.configs
            .where((c) => c.typeRoom?.typeRoomId == selectedTypeRoomId)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng giá phòng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(priceConfigListProvider.notifier).loadData(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bộ lọc theo Loại phòng
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Text('Loại phòng: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: selectedTypeRoomId,
                          hint: const Text('Tất cả'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Tất cả loại phòng')),
                            ...state.typeRooms.map((tr) => DropdownMenuItem(
                                  value: tr.typeRoomId,
                                  child: Text(tr.typeRoom),
                                )),
                          ],
                          onChanged: (val) => setState(() => selectedTypeRoomId = val),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredConfigs.isEmpty
                      ? const Center(child: Text('Chưa có cấu hình giá'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredConfigs.length,
                          itemBuilder: (context, index) {
                            final config = filteredConfigs[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.shade100,
                                  child: const Icon(Icons.attach_money, color: Colors.green),
                                ),
                                title: Text(
                                  '${config.typeRoom?.typeRoom ?? "Loại phòng"} — ${config.typeBooking?.typeName ?? "Combo"}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Mã combo: ${config.typeBooking?.bookingCode ?? "N/A"}'),
                                    Text(
                                      'Giá: ${config.price.toInt()} VNĐ',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showPriceDialog(config),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmDelete(config.priceConfigId!),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(state),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Form Sửa giá gói đã có ──────────────────────────────────────────────────
  void _showPriceDialog(PriceConfigModel config) {
    final priceController = TextEditingController(text: config.price.toInt().toString());

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.price_change, color: Color(0xFF9462FF)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sửa giá: ${config.typeRoom?.typeRoom} - ${config.typeBooking?.typeName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel('Giá tiền mới (VNĐ)'),
                const SizedBox(height: 4),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    hintText: 'VD: 250000',
                    prefixIcon: const Icon(Icons.attach_money, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
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
              final newPrice = double.tryParse(priceController.text.trim()) ?? config.price;
              final updated = PriceConfigModel(
                priceConfigId: config.priceConfigId,
                typeRoom: config.typeRoom,
                typeBooking: config.typeBooking,
                price: newPrice,
              );

              final success = await ref
                  .read(priceConfigListProvider.notifier)
                  .updatePriceConfig(config.priceConfigId!, updated);

              if (mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Cập nhật giá thành công' : 'Thất bại'),
                  ),
                );
              }
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Form Tạo gói combo & giá mới hoàn toàn ─────────────────────────────────
  void _showAddDialog(PriceConfigListState state) {
    TypeRoomModel? selectedRoomType = state.typeRooms.isNotEmpty ? state.typeRooms.first : null;
    final comboNameController = TextEditingController();
    final comboCodeController = TextEditingController();
    final hoursController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.add_card, color: Color(0xFF9462FF)),
                SizedBox(width: 10),
                Text('Tạo gói combo & giá mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                      _buildFieldLabel('Loại phòng áp dụng'),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<TypeRoomModel>(
                        isExpanded: true,
                        initialValue: selectedRoomType,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.meeting_room, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: state.typeRooms
                            .map((tr) => DropdownMenuItem(value: tr, child: Text(tr.typeRoom, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) => setModalState(() => selectedRoomType = val),
                      ),
                      const SizedBox(height: 12),
                      _buildFieldLabel('Tên gói Combo mới'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: comboNameController,
                        decoration: InputDecoration(
                          hintText: 'VD: Combo 8h xem phim + đồ ăn',
                          prefixIcon: const Icon(Icons.label, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFieldLabel('Mã Combo'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: comboCodeController,
                        decoration: InputDecoration(
                          hintText: 'VD: COMBO_8H',
                          prefixIcon: const Icon(Icons.qr_code, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFieldLabel('Số giờ thuê (nếu có)'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: hoursController,
                        decoration: InputDecoration(
                          hintText: 'VD: 8',
                          prefixIcon: const Icon(Icons.timer, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildFieldLabel('Giá tiền (VNĐ)'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: priceController,
                        decoration: InputDecoration(
                          hintText: 'VD: 350000',
                          prefixIcon: const Icon(Icons.attach_money, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
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
                  if (selectedRoomType == null || comboNameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập tên gói combo và chọn loại phòng')),
                    );
                    return;
                  }

                  final code = comboCodeController.text.trim().isNotEmpty
                      ? comboCodeController.text.trim().toUpperCase()
                      : 'COMBO_${DateTime.now().millisecondsSinceEpoch % 100000}';

                  // 1. Tạo loại Combo mới ở Backend
                  final newCombo = TypeBookingModel(
                    typeBookingId: 'TB_$code',
                    typeName: comboNameController.text.trim(),
                    bookingCode: code,
                    durationHours: int.tryParse(hoursController.text.trim()),
                  );

                  final notifier = ref.read(priceConfigListProvider.notifier);
                  final comboSuccess = await notifier.createTypeBooking(newCombo);

                  if (!comboSuccess) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tạo gói Combo mới thất bại')),
                      );
                    }
                    return;
                  }

                  // 2. Tạo Cấu hình giá tiền cho gói Combo mới vừa tạo
                  final newConfig = PriceConfigModel(
                    typeRoom: selectedRoomType,
                    typeBooking: newCombo,
                    price: double.tryParse(priceController.text.trim()) ?? 0,
                  );

                  final configSuccess = await notifier.createPriceConfig(newConfig);

                  if (mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(configSuccess
                            ? 'Đã tạo gói combo & cấu hình giá mới thành công'
                            : 'Tạo cấu hình giá thất bại'),
                      ),
                    );
                  }
                },
                child: const Text('Tạo mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa cấu hình giá này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await ref.read(priceConfigListProvider.notifier).deletePriceConfig(id);
              if (mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Đã xóa cấu hình giá' : 'Xóa thất bại'),
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
