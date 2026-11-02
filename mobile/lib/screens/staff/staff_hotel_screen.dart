// lib/screens/staff/staff_hotel_screen.dart
// Phụ trách: TV5

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/room_model.dart';
import '../../providers/hotel_provider.dart';

class StaffHotelScreen extends ConsumerStatefulWidget {
  const StaffHotelScreen({super.key});

  @override
  ConsumerState<StaffHotelScreen> createState() => _StaffHotelScreenState();
}

class _StaffHotelScreenState extends ConsumerState<StaffHotelScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hotelListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý chi nhánh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(hotelListProvider.notifier).loadHotels(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.hotels.isEmpty
              ? const Center(child: Text('Chưa có chi nhánh nào'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.hotels.length,
                  itemBuilder: (context, index) {
                    final hotel = state.hotels[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: const Icon(Icons.store, color: Colors.indigo),
                        ),
                        title: Text(
                          hotel.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Mã: ${hotel.hotelId}'),
                            Text('Địa chỉ: ${hotel.address}'),
                            if (hotel.phone != null) Text('SĐT: ${hotel.phone}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showHotelDialog(hotel: hotel),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(hotel.hotelId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHotelDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showHotelDialog({HotelModel? hotel}) {
    final isEdit = hotel != null;
    final idController = TextEditingController(text: hotel?.hotelId ?? '');
    final nameController = TextEditingController(text: hotel?.name ?? '');
    final addressController = TextEditingController(text: hotel?.address ?? '');
    final phoneController = TextEditingController(text: hotel?.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Sửa chi nhánh' : 'Thêm chi nhánh'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEdit)
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: 'Mã chi nhánh (VD: HN010)'),
                ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên chi nhánh'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
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
              final newHotel = HotelModel(
                hotelId: isEdit ? hotel.hotelId : idController.text.trim(),
                name: nameController.text.trim(),
                address: addressController.text.trim(),
                phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
              );

              final notifier = ref.read(hotelListProvider.notifier);
              final success = isEdit
                  ? await notifier.updateHotel(hotel.hotelId, newHotel)
                  : await notifier.createHotel(newHotel);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? (isEdit ? 'Đã cập nhật chi nhánh' : 'Đã thêm chi nhánh')
                        : 'Có lỗi xảy ra'),
                  ),
                );
              }
            },
            child: Text(isEdit ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa chi nhánh $id không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await ref.read(hotelListProvider.notifier).deleteHotel(id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Đã xóa chi nhánh' : 'Xóa thất bại'),
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
