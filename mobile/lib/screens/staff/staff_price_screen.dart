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
                      DropdownButton<String?>(
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
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showPriceDialog(config),
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

  void _showPriceDialog(PriceConfigModel config) {
    final priceController = TextEditingController(text: config.price.toInt().toString());

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
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
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextField(
            controller: priceController,
            decoration: InputDecoration(
              labelText: 'Giá tiền mới (VNĐ)',
              prefixIcon: const Icon(Icons.attach_money, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.number,
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

  void _showAddDialog(PriceConfigListState state) {
    TypeRoomModel? selectedRoomType = state.typeRooms.isNotEmpty ? state.typeRooms.first : null;
    TypeBookingModel? selectedBookingType = state.typeBookings.isNotEmpty ? state.typeBookings.first : null;
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.add_card, color: Color(0xFF9462FF)),
                SizedBox(width: 10),
                Text('Thêm cấu hình giá mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<TypeRoomModel>(
                      initialValue: selectedRoomType,
                      decoration: InputDecoration(
                        labelText: 'Loại phòng',
                        prefixIcon: const Icon(Icons.meeting_room, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: state.typeRooms
                          .map((tr) => DropdownMenuItem(value: tr, child: Text(tr.typeRoom)))
                          .toList(),
                      onChanged: (val) => setModalState(() => selectedRoomType = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TypeBookingModel>(
                      initialValue: selectedBookingType,
                      decoration: InputDecoration(
                        labelText: 'Loại Combo',
                        prefixIcon: const Icon(Icons.category, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: state.typeBookings
                          .map((tb) => DropdownMenuItem(value: tb, child: Text(tb.typeName)))
                          .toList(),
                      onChanged: (val) => setModalState(() => selectedBookingType = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Giá tiền (VNĐ)',
                        prefixIcon: const Icon(Icons.attach_money, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  if (selectedRoomType == null || selectedBookingType == null) return;
                  final newConfig = PriceConfigModel(
                    typeRoom: selectedRoomType,
                    typeBooking: selectedBookingType,
                    price: double.tryParse(priceController.text.trim()) ?? 0,
                  );

                  final success = await ref
                      .read(priceConfigListProvider.notifier)
                      .createPriceConfig(newConfig);

                  if (mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Thêm cấu hình giá thành công' : 'Thất bại'),
                      ),
                    );
                  }
                },
                child: const Text('Thêm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
