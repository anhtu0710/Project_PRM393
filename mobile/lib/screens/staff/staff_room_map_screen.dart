// lib/screens/staff/staff_room_map_screen.dart
// Phụ trách: TV5 — Sơ đồ & Quản lý phòng Hợp nhất

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/room_model.dart';
import '../../providers/hotel_provider.dart';
import '../../providers/price_config_provider.dart';
import '../../providers/room_provider.dart';

class StaffRoomMapScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const StaffRoomMapScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<StaffRoomMapScreen> createState() => _StaffRoomMapScreenState();
}

class _StaffRoomMapScreenState extends ConsumerState<StaffRoomMapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? selectedHotelId;
  String? selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Color(0xFF4B5563),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomListProvider);
    final hotelState = ref.watch(hotelListProvider);
    final priceState = ref.watch(priceConfigListProvider);

    final filteredRooms = roomState.rooms.where((r) {
      final matchesHotel = selectedHotelId == null || r.hotel?.hotelId == selectedHotelId;
      final normalizedStatus = _normalizeStatus(r.status);
      final matchesStatus = selectedStatusFilter == null || normalizedStatus == selectedStatusFilter;
      return matchesHotel && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sơ đồ & Quản lý phòng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(roomListProvider.notifier).loadRooms(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view_rounded), text: 'Sơ đồ Realtime'),
            Tab(icon: Icon(Icons.format_list_bulleted_rounded), text: 'Danh sách & Quản lý'),
          ],
        ),
      ),
      body: roomState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Double Filters: Chi nhánh & Trạng thái phòng ───────────────
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Filter 1: Chi nhánh
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          initialValue: selectedHotelId,
                          decoration: InputDecoration(
                            labelText: 'Chi nhánh',
                            prefixIcon: const Icon(Icons.storefront, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
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
                      const SizedBox(width: 10),
                      // Filter 2: Trạng thái
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          initialValue: selectedStatusFilter,
                          decoration: InputDecoration(
                            labelText: 'Trạng thái',
                            prefixIcon: const Icon(Icons.filter_alt, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
                            DropdownMenuItem(value: 'Trống', child: Text('Trống')),
                            DropdownMenuItem(value: 'Đang dùng', child: Text('Đang dùng')),
                            DropdownMenuItem(value: 'Đang dọn', child: Text('Đang dọn')),
                          ],
                          onChanged: (val) => setState(() => selectedStatusFilter = val),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 0: Sơ đồ phòng Realtime (Grid)
                      _buildRoomGrid(filteredRooms),
                      // TAB 1: Danh sách Quản lý phòng (List + Thêm/Sửa/Xóa)
                      _buildRoomList(filteredRooms, hotelState.hotels, priceState.typeRooms),
                    ],
                  ),
                ),
              ],
            ),
      // Nút "Thêm phòng" CHỈ HIỂN THỊ khi ở Tab 1 (Danh sách & Quản lý)
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF9462FF),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Thêm phòng mới',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => _showRoomDialog(hotelState.hotels, priceState.typeRooms),
            )
          : null,
    );
  }

  // ── TAB 0: Sơ đồ Realtime dạng Grid ───────────────────────────────────────
  Widget _buildRoomGrid(List<RoomModel> rooms) {
    if (rooms.isEmpty) {
      return const Center(child: Text('Không có phòng nào theo bộ lọc'));
    }

    return Column(
      children: [
        // Legend Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
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
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
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
    );
  }

  // ── TAB 1: Danh sách & Quản lý phòng (List) ──────────────────────────────
  Widget _buildRoomList(List<RoomModel> rooms, List<HotelModel> hotels, List<TypeRoomModel> typeRooms) {
    if (rooms.isEmpty) {
      return const Center(child: Text('Chưa có phòng nào theo bộ lọc'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    room.status ?? 'Trống',
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showRoomDialog(hotels, typeRooms, room: room),
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
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
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
                onPressed: () => Navigator.pop(dialogCtx),
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
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Đã đổi trạng thái phòng'
                            : 'Đổi trạng thái thất bại'),
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

  void _showRoomDialog(List<HotelModel> hotels, List<TypeRoomModel> typeRooms,
      {RoomModel? room}) {
    final isEdit = room != null;
    final idController = TextEditingController(text: room?.roomId ?? '');
    final nameController = TextEditingController(text: room?.nameRoom ?? '');

    HotelModel? selectedHotel = isEdit
        ? hotels.firstWhere((h) => h.hotelId == room.hotel?.hotelId,
            orElse: () => hotels.first)
        : (hotels.isNotEmpty ? hotels.first : null);

    TypeRoomModel? selectedType = isEdit
        ? typeRooms.firstWhere((t) => t.typeRoomId == room.typeRoom?.typeRoomId,
            orElse: () => typeRooms.first)
        : (typeRooms.isNotEmpty ? typeRooms.first : null);

    String selectedStatus = room?.status ?? 'Trống';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return AlertDialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_sharp : Icons.add_business_rounded,
                  color: const Color(0xFF9462FF),
                ),
                const SizedBox(width: 10),
                Text(
                  isEdit ? 'Sửa phòng ${room.roomId}' : 'Thêm phòng mới',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
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
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
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
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
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
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          items: hotels
                              .map((h) => DropdownMenuItem(
                                  value: h,
                                  child: Text(h.name,
                                      overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (val) =>
                              setModalState(() => selectedHotel = val),
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
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          items: typeRooms
                              .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.typeRoom,
                                      overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (val) =>
                              setModalState(() => selectedType = val),
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
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Trống', child: Text('Trống')),
                          DropdownMenuItem(
                              value: 'Đang dùng', child: Text('Đang dùng')),
                          DropdownMenuItem(
                              value: 'Đang dọn', child: Text('Đang dọn')),
                        ],
                        onChanged: (val) =>
                            setModalState(() => selectedStatus = val!),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
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
                            ? (isEdit
                                ? 'Đã cập nhật phòng'
                                : 'Đã thêm phòng')
                            : 'Có lỗi xảy ra'),
                      ),
                    );
                  }
                },
                child: Text(isEdit ? 'Lưu' : 'Thêm',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
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
              final errorMsg =
                  await ref.read(roomListProvider.notifier).deleteRoom(roomId);
              if (!mounted) return;
              Navigator.pop(dialogCtx);
              if (errorMsg != null) {
                // Hiển thị thông báo lỗi nếu phòng bị chặn xóa do có booking
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Không thể xóa',
                        style: TextStyle(color: Colors.red)),
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
        ]      ),
    );
  }
}
