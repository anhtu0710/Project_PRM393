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
                                  backgroundColor: statusColor.withOpacity(0.2),
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
                                        color: statusColor.withOpacity(0.1),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(isEdit ? 'Sửa phòng ${room.roomId}' : 'Thêm phòng mới'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isEdit)
                    TextField(
                      controller: idController,
                      decoration: const InputDecoration(labelText: 'Mã phòng (VD: HN001_Q03)'),
                    ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Tên phòng (VD: Queen 03)'),
                  ),
                  if (hotels.isNotEmpty)
                    DropdownButtonFormField<HotelModel>(
                      value: selectedHotel,
                      decoration: const InputDecoration(labelText: 'Chi nhánh'),
                      items: hotels
                          .map((h) => DropdownMenuItem(value: h, child: Text(h.name)))
                          .toList(),
                      onChanged: (val) => setModalState(() => selectedHotel = val),
                    ),
                  if (typeRooms.isNotEmpty)
                    DropdownButtonFormField<TypeRoomModel>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Loại phòng'),
                      items: typeRooms
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.typeRoom)))
                          .toList(),
                      onChanged: (val) => setModalState(() => selectedType = val),
                    ),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Trạng thái'),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
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
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? (isEdit ? 'Đã cập nhật phòng' : 'Đã thêm phòng')
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
