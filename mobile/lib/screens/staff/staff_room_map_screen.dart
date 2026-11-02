// lib/screens/staff/staff_room_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/room_model.dart';
import '../../providers/hotel_provider.dart';
import '../../providers/room_provider.dart';

class StaffRoomMapScreen extends ConsumerStatefulWidget {
  const StaffRoomMapScreen({super.key});

  @override
  ConsumerState<StaffRoomMapScreen> createState() => _StaffRoomMapScreenState();
}

class _StaffRoomMapScreenState extends ConsumerState<StaffRoomMapScreen> {
  String? selectedHotelId;

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomListProvider);
    final hotelState = ref.watch(hotelListProvider);

    final filteredRooms = selectedHotelId == null
        ? roomState.rooms
        : roomState.rooms
            .where((r) => r.hotel?.hotelId == selectedHotelId)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sơ đồ phòng realtime'),
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
                // Legend Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _legendItem('Trống', Colors.green),
                      _legendItem('Đang dùng', Colors.red),
                      _legendItem('Đang dọn', Colors.orange),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filteredRooms.isEmpty
                      ? const Center(child: Text('Không có phòng nào'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filteredRooms.length,
                          itemBuilder: (context, index) {
                            final room = filteredRooms[index];
                            final color = _statusColor(room.status);

                            return InkWell(
                              onTap: () => _showStatusChangeDialog(room),
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: color, width: 2),
                                ),
                                color: color.withValues(alpha: 0.1),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.meeting_room, size: 36, color: color),
                                      const SizedBox(height: 4),
                                      Text(
                                        room.nameRoom,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: color.shade900,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      Text(
                                        '(${room.roomId})',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          room.status ?? 'Trống',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _legendItem(String label, MaterialColor color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _normalizeStatus(String? status) {
    if (status == null) return 'Trống';
    final s = status.trim();
    if (s == 'Đang dọn' || s == 'CLEANING') return 'Đang dọn';
    if (s == 'Đang dùng' || s == 'OCCUPIED') return 'Đang dùng';
    return 'Trống';
  }

  MaterialColor _statusColor(String? status) {
    final s = _normalizeStatus(status);
    if (s == 'Đang dùng') return Colors.red;
    if (s == 'Đang dọn') return Colors.orange;
    return Colors.green;
  }

  void _showStatusChangeDialog(RoomModel room) {
    String currentStatus = _normalizeStatus(room.status);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('Đổi trạng thái phòng ${room.nameRoom}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Trống (AVAILABLE)'),
                  value: 'Trống',
                  groupValue: currentStatus,
                  activeColor: Colors.green,
                  onChanged: (val) => setModalState(() => currentStatus = val!),
                ),
                RadioListTile<String>(
                  title: const Text('Đang dùng (OCCUPIED)'),
                  value: 'Đang dùng',
                  groupValue: currentStatus,
                  activeColor: Colors.red,
                  onChanged: (val) => setModalState(() => currentStatus = val!),
                ),
                RadioListTile<String>(
                  title: const Text('Đang dọn (CLEANING)'),
                  value: 'Đang dọn',
                  groupValue: currentStatus,
                  activeColor: Colors.orange,
                  onChanged: (val) => setModalState(() => currentStatus = val!),
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
                  final updatedRoom = RoomModel(
                    roomId: room.roomId,
                    nameRoom: room.nameRoom,
                    hotel: room.hotel,
                    typeRoom: room.typeRoom,
                    status: currentStatus,
                    imageUrl: room.imageUrl,
                  );

                  final success = await ref
                      .read(roomListProvider.notifier)
                      .updateRoom(room.roomId, updatedRoom);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Đã đổi trạng thái phòng' : 'Đổi trạng thái thất bại'),
                      ),
                    );
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }
}
