// lib/screens/staff/staff_hotel_screen.dart
// Phụ trách: TV5

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/room_model.dart';
import '../../providers/auth_provider.dart';
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
    final authState = ref.watch(authProvider);

    final currentUser = authState.user;
    final isAdmin = currentUser?.role.toUpperCase() == 'ADMIN';
    final staffHotelId = currentUser?.hotelId;

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
          : state.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(
                          'Lỗi tải chi nhánh:\n${state.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9462FF)),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                          onPressed: () => ref.read(hotelListProvider.notifier).loadHotels(),
                        ),
                      ],
                    ),
                  ),
                )
              : state.hotels.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Chưa có chi nhánh nào trong hệ thống', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => ref.read(hotelListProvider.notifier).loadHotels(),
                            child: const Text('Tải lại'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: state.hotels.length,
                      itemBuilder: (context, index) {
                        final hotel = state.hotels[index];
                        final canEdit = isAdmin || (staffHotelId != null && hotel.hotelId == staffHotelId);

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
                                if (!canEdit)
                                  const Text(
                                    '🔒 Khóa chỉnh sửa (Không thuộc cơ sở phân công)',
                                    style: TextStyle(fontSize: 11, color: Colors.redAccent, fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: canEdit ? Colors.blue : Colors.grey),
                                  tooltip: canEdit ? 'Sửa chi nhánh' : 'Chỉ được sửa chi nhánh được phân công',
                                  onPressed: () {
                                    if (!canEdit) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Bạn chỉ có quyền chỉnh sửa chi nhánh được phân công (${currentUser?.hotelName ?? ''}).')),
                                      );
                                      return;
                                    }
                                    _showHotelDialog(hotel: hotel);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: canEdit ? Colors.red : Colors.grey),
                                  tooltip: canEdit ? 'Xóa chi nhánh' : 'Chỉ được xóa chi nhánh được phân công',
                                  onPressed: () {
                                    if (!canEdit) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Bạn chỉ có quyền xóa chi nhánh được phân công.')),
                                      );
                                      return;
                                    }
                                    _confirmDelete(hotel.hotelId);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!isAdmin && staffHotelId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tài khoản nhân viên chưa được gán cơ sở, không thể thêm chi nhánh.')),
            );
            return;
          }
          _showHotelDialog();
        },
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
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isEdit ? Icons.edit_location : Icons.add_location_alt,
              color: const Color(0xFF9462FF),
            ),
            const SizedBox(width: 10),
            Text(
              isEdit ? 'Sửa chi nhánh' : 'Thêm chi nhánh mới',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isEdit) ...[
                  TextField(
                    controller: idController,
                    decoration: InputDecoration(
                      labelText: 'Mã chi nhánh (VD: HN010)',
                      prefixIcon: const Icon(Icons.qr_code, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên chi nhánh',
                    prefixIcon: const Icon(Icons.store, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ',
                    prefixIcon: const Icon(Icons.location_on, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: const Icon(Icons.phone, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.phone,
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
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? (isEdit ? 'Đã cập nhật chi nhánh' : 'Đã thêm chi nhánh')
                        : 'Có lỗi xảy ra'),
                  ),
                );
              }
            },
            child: Text(isEdit ? 'Lưu' : 'Thêm', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa chi nhánh $id không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final errorMsg = await ref.read(hotelListProvider.notifier).deleteHotel(id);
              if (!mounted) return;
              Navigator.pop(dialogCtx);
              if (errorMsg != null) {
                // Hiển thị dialog báo lỗi lý do không thể xóa chi nhánh
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Không thể xóa', style: TextStyle(color: Colors.red)),
                    content: Text(errorMsg),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Đã hiểu'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa chi nhánh thành công')),
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
