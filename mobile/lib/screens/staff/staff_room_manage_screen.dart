// lib/screens/staff/staff_room_manage_screen.dart
// Phụ trách: TV5

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/room_model.dart';
import '../../providers/hotel_provider.dart';
import '../../providers/price_config_provider.dart';
import '../../providers/room_provider.dart';

class StaffRoomManageScreen extends ConsumerStatefulWidget {
  const StaffRoomManageScreen({super.key});

  @override
  ConsumerState<StaffRoomManageScreen> createState() => _StaffRoomManageScreenState();
}

class _StaffRoomManageScreenState extends ConsumerState<StaffRoomManageScreen> {
  String? selectedHotelId;

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomListProvider);
    final hotelState = ref.watch(hotelListProvider);
    final priceState = ref.watch(priceConfigListProvider);

    final filteredRooms = selectedHotelId == null
        ? roomState.rooms
        : roomState.rooms
            .where((r) => r.hotel?.hotelId == selectedHotelId)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý phòng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(roomListProvider.notifier).loadRooms(),
          ),
        ],
      ),
      body: roomState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter by Hotel
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Text('Chi nhánh: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: selectedHotelId,
                          hint: const Text('Tất cả chi nhánh'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Tất cả chi nhánh')),
                            ...hotelState.hotels.map((h) => DropdownMenuItem(
                                  value: h.hotelId,
                                  child: Text(h.name, overflow: TextOverflow.ellipsis),
                                )),
                          ],
                          onChanged: (val) => setState(() => selectedHotelId = val),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredRooms.isEmpty
                      ? const Center(child: Text('Chưa có phòng nào'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredRooms.length,
                          itemBuilder: (context, index) {
                            final room = filteredRooms[index];
                            final statusColor = _statusColor(room.status);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  backgroundColor: statusColor.withValues(alpha: 0.2),
                                  child: Icon(Icons.meeting_room, color: statusColor),
                                ),
                                title: Text(
                                  '${room.nameRoom} (${room.roomId})',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Loại: ${room.typeRoom?.typeRoom ?? "N/A"}'),
                                    Text('Cơ sở: ${room.hotel?.name ?? "N/A"}'),
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: statusColor),
                                      ),
                                      child: Text(
                                        room.status ?? 'Trống',
                                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showRoomDialog(hotelState.hotels, priceState.typeRooms, room: room),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmDelete(room.roomId),
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
        onPressed: () => _showRoomDialog(hotelState.hotels, priceState.typeRooms),
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _statusColor(String? status) {
    if (status == 'Đang dùng' || status == 'OCCUPIED') return Colors.red;
    if (status == 'Đang dọn' || status == 'CLEANING') return Colors.orange;
    return Colors.green;
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF4B5563)),
    );
  }

  void _showRoomDialog(List<HotelModel> hotels, List<TypeRoomModel> typeRooms, {RoomModel? room}) {
    final isEdit = room != null;
    final idController = TextEditingController(text: room?.roomId ?? '');
    final nameController = TextEditingController(text: room?.nameRoom ?? '');

    HotelModel? selectedHotel = isEdit
        ? hotels.firstWhere((h) => h.hotelId == room.hotel?.hotelId, orElse: () => hotels.first)
        : (hotels.isNotEmpty ? hotels.first : null);

    TypeRoomModel? selectedType = isEdit
        ? typeRooms.firstWhere((t) => t.typeRoomId == room.typeRoom?.typeRoomId, orElse: () => typeRooms.first)
        : (typeRooms.isNotEmpty ? typeRooms.first : null);

    String selectedStatus = room?.status ?? 'Trống';

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
                  isEdit ? Icons.edit_sharp : Icons.add_business_rounded,
                  color: const Color(0xFF9462FF),
                ),
                const SizedBox(width: 10),
                Text(
                  isEdit ? 'Sửa phòng ${room.roomId}' : 'Thêm phòng mới',
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
                      if (!isEdit) ...[
                        _buildFieldLabel('Mã phòng'),
                        const SizedBox(height: 4),
                        TextField(
                          controller: idController,
                          decoration: InputDecoration(
                            hintText: 'VD: HN001_Q03',
                            prefixIcon: const Icon(Icons.qr_code, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildFieldLabel('Tên phòng'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'VD: Queen 03',
                          prefixIcon: const Icon(Icons.meeting_room, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (hotels.isNotEmpty) ...[
                        _buildFieldLabel('Chi nhánh'),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<HotelModel>(
                          isExpanded: true,
                          initialValue: selectedHotel,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.storefront, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: hotels
                              .map((h) => DropdownMenuItem(value: h, child: Text(h.name, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (val) => setModalState(() => selectedHotel = val),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (typeRooms.isNotEmpty) ...[
                        _buildFieldLabel('Loại phòng'),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<TypeRoomModel>(
                          isExpanded: true,
                          initialValue: selectedType,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.category, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: typeRooms
                              .map((t) => DropdownMenuItem(value: t, child: Text(t.typeRoom, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (val) => setModalState(() => selectedType = val),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildFieldLabel('Trạng thái'),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedStatus,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.info_outline, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Trống', child: Text('Trống')),
                          DropdownMenuItem(value: 'Đang dùng', child: Text('Đang dùng')),
                          DropdownMenuItem(value: 'Đang dọn', child: Text('Đang dọn')),
                        ],
                        onChanged: (val) => setModalState(() => selectedStatus = val!),
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
                  final newRoom = RoomModel(
                    roomId: isEdit ? room.roomId : idController.text.trim(),
                    nameRoom: nameController.text.trim(),
                    hotel: selectedHotel,
                    typeRoom: selectedType,
                    status: selectedStatus,
                  );

                  final notifier = ref.read(roomListProvider.notifier);
                  final success = isEdit
                      ? await notifier.updateRoom(room.roomId, newRoom)
                      : await notifier.createRoom(newRoom);

                  if (mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? (isEdit ? 'Đã cập nhật phòng' : 'Đã thêm phòng')
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

  void _confirmDelete(String roomId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa phòng $roomId không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final errorMsg = await ref.read(roomListProvider.notifier).deleteRoom(roomId);
              if (!mounted) return;
              Navigator.pop(dialogCtx);
              if (errorMsg != null) {
                // Hiển thị thông báo lỗi nếu phòng bị chặn xóa do có booking
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
                  const SnackBar(content: Text('Đã xóa phòng thành công')),
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
