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
      builder: (context) => AlertDialog(
        title: Text('Sửa giá: ${config.typeRoom?.typeRoom} - ${config.typeBooking?.typeName}'),
        content: TextField(
          controller: priceController,
          decoration: const InputDecoration(labelText: 'Giá tiền mới (VNĐ)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Cập nhật giá thành công' : 'Thất bại'),
                  ),
                );
              }
            },
            child: const Text('Lưu'),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Thêm cấu hình giá mới'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TypeRoomModel>(
                  value: selectedRoomType,
                  decoration: const InputDecoration(labelText: 'Loại phòng'),
                  items: state.typeRooms
                      .map((tr) => DropdownMenuItem(value: tr, child: Text(tr.typeRoom)))
                      .toList(),
                  onChanged: (val) => setModalState(() => selectedRoomType = val),
                ),
                DropdownButtonFormField<TypeBookingModel>(
                  value: selectedBookingType,
                  decoration: const InputDecoration(labelText: 'Loại Combo'),
                  items: state.typeBookings
                      .map((tb) => DropdownMenuItem(value: tb, child: Text(tb.typeName)))
                      .toList(),
                  onChanged: (val) => setModalState(() => selectedBookingType = val),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Giá tiền (VNĐ)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
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
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Thêm cấu hình giá thành công' : 'Thất bại'),
                      ),
                    );
                  }
                },
                child: const Text('Thêm'),
              ),
            ],
          );
        },
      ),
    );
  }
}
