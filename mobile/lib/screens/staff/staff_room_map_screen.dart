// lib/screens/staff/staff_room_map_screen.dart
// Phụ trách: TV5 — Sơ đồ & Quản lý phòng Hợp nhất

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../models/room_model.dart';
import '../../providers/auth_provider.dart';
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
    final authState = ref.watch(authProvider);

    final currentUser = authState.user;
    final isAdmin = currentUser?.role.toUpperCase() == 'ADMIN';
    final staffHotelId = currentUser?.hotelId?.trim().toLowerCase();

    final filteredRooms = roomState.rooms.where((r) {
      final matchesHotel = selectedHotelId == null || r.hotel?.hotelId == selectedHotelId;
      final normalizedStatus = _normalizeStatus(r.status);
      final matchesStatus = selectedStatusFilter == null || normalizedStatus == selectedStatusFilter;
      return matchesHotel && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Sơ đồ & Quản lý phòng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(roomListProvider.notifier).loadRooms();
              ref.read(hotelListProvider.notifier).loadHotels();
            },
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
      body: roomState.isLoading || hotelState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : roomState.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(
                          'Lỗi tải danh sách phòng:\n${roomState.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9462FF)),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                          onPressed: () => ref.read(roomListProvider.notifier).loadRooms(),
                        ),
                      ],
                    ),
                  ),
                )
              : hotelState.error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                            const SizedBox(height: 12),
                            Text(
                              'Lỗi tải chi nhánh:\n${hotelState.error}',
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
                                  value: selectedHotelId,
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
                                  value: selectedStatusFilter,
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
                              _buildRoomGrid(filteredRooms, isAdmin, staffHotelId, currentUser),
                              // TAB 1: Danh sách Quản lý phòng (List + Thêm/Sửa/Xóa)
                              _buildRoomList(filteredRooms, hotelState.hotels, priceState.typeRooms, isAdmin, staffHotelId, currentUser),
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
              onPressed: () {
                if (!isAdmin && (staffHotelId == null || staffHotelId.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tài khoản nhân viên chưa được gán cơ sở, không thể thêm phòng.')),
                  );
                  return;
                }
                _showRoomDialog(hotelState.hotels, priceState.typeRooms);
              },
            )
          : null,
    );
  }

  // ── TAB 0: Sơ đồ Realtime dạng Grid (Thẩm mỹ cao, phân quyền trạng thái) ────
  Widget _buildRoomGrid(
    List<RoomModel> rooms,
    bool isAdmin,
    String? staffHotelId,
    dynamic currentUser,
  ) {
    if (rooms.isEmpty) {
      return const Center(child: Text('Không có phòng nào theo bộ lọc'));
    }

    return Column(
      children: [
        // Legend Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _legendItem('Trống', Colors.green),
                _legendItem('Đang dùng', Colors.red),
                _legendItem('Đang dọn', Colors.orange),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final color = _statusColor(room.status);
              final roomHotelId = room.hotel?.hotelId.toLowerCase();
              final canEdit = isAdmin || (staffHotelId != null && staffHotelId.isNotEmpty && roomHotelId == staffHotelId);

              return InkWell(
                onTap: () {
                  if (!canEdit) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bạn chỉ có quyền thay đổi trạng thái phòng thuộc cơ sở được phân công (${currentUser?.hotelName ?? ''}).')),
                    );
                    return;
                  }
                  _showStatusChangeDialog(room);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.meeting_room_rounded, size: 28, color: color),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              room.nameRoom,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.storefront_rounded, size: 12, color: AppTheme.textGray),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    room.hotel?.name ?? 'GenZ Cinema',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textGray),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                room.status ?? 'Trống',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!canEdit)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_rounded, size: 14, color: Colors.grey),
                          ),
                        ),
                    ],
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
  Widget _buildRoomList(
    List<RoomModel> rooms,
    List<HotelModel> hotels,
    List<TypeRoomModel> typeRooms,
    bool isAdmin,
    String? staffHotelId,
    dynamic currentUser,
  ) {
    if (rooms.isEmpty) {
      return const Center(child: Text('Chưa có phòng nào theo bộ lọc'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final statusColor = _statusColor(room.status);
        final roomHotelId = room.hotel?.hotelId.toLowerCase();
        final canEdit = isAdmin || (staffHotelId != null && staffHotelId.isNotEmpty && roomHotelId == staffHotelId);

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
              room.nameRoom,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Loại: ${room.typeRoom?.typeRoom ?? "N/A"}'),
                Text('Cơ sở: ${room.hotel?.name ?? "N/A"}'),
                if (!canEdit)
                  const Text(
                    '🔒 Khóa chỉnh sửa (Không thuộc cơ sở phân công)',
                    style: TextStyle(fontSize: 11, color: Colors.redAccent, fontStyle: FontStyle.italic),
                  ),
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
                  icon: Icon(Icons.edit, color: canEdit ? Colors.blue : Colors.grey),
                  tooltip: canEdit ? 'Sửa phòng' : 'Chỉ được sửa phòng thuộc cơ sở phân công',
                  onPressed: () {
                    if (!canEdit) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Bạn chỉ có quyền chỉnh sửa phòng thuộc cơ sở được phân công (${currentUser?.hotelName ?? ''}).')),
                      );
                      return;
                    }
                    _showRoomDialog(hotels, typeRooms, room: room);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: canEdit ? Colors.red : Colors.grey),
                  tooltip: canEdit ? 'Xóa phòng' : 'Chỉ được xóa phòng thuộc cơ sở phân công',
                  onPressed: () {
                    if (!canEdit) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bạn chỉ có quyền xóa phòng thuộc cơ sở được phân công.')),
                      );
                      return;
                    }
                    _confirmDelete(room.roomId);
                  },
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
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9462FF)),
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  try {
                    final updated = RoomModel(
                      roomId: room.roomId,
                      nameRoom: room.nameRoom,
                      typeRoom: room.typeRoom,
                      status: currentStatus,
                      hotel: room.hotel,
                      imageUrl: room.imageUrl,
                      description: room.description,
                      amenities: room.amenities,
                      averageRating: room.averageRating,
                      reviewCount: room.reviewCount,
                      priceOptions: room.priceOptions,
                      reviews: room.reviews,
                    );
                    final success = await ref.read(roomListProvider.notifier).updateRoom(room.roomId, updated);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Đổi trạng thái phòng thành công' : 'Thất bại')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Thất bại: $e')),
                      );
                    }
                  }
                },
                child: const Text('Lưu', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRoomDialog(List<HotelModel> hotels, List<TypeRoomModel> typeRooms, {RoomModel? room}) {
    final isEdit = room != null;
    final roomIdController = TextEditingController(text: room?.roomId ?? '');
    final nameController = TextEditingController(text: room?.nameRoom ?? '');
    final imageController = TextEditingController(text: room?.imageUrl ?? '');

    String? selectedHotelId = room?.hotel?.hotelId ?? (hotels.isNotEmpty ? hotels.first.hotelId : null);
    String? selectedTypeRoomId = room?.typeRoom?.typeRoomId ?? (typeRooms.isNotEmpty ? typeRooms.first.typeRoomId : null);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? 'Sửa thông tin phòng' : 'Thêm phòng mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isEdit) ...[
                  _buildFieldLabel('Mã phòng (VD: room_hn_01)'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: roomIdController,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildFieldLabel('Tên phòng'),
                const SizedBox(height: 4),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 12),
                _buildFieldLabel('Chi nhánh (Cơ sở)'),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedHotelId,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: hotels.map((h) => DropdownMenuItem(value: h.hotelId, child: Text(h.name))).toList(),
                  onChanged: (val) => setModalState(() => selectedHotelId = val),
                ),
                const SizedBox(height: 12),
                _buildFieldLabel('Loại phòng'),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedTypeRoomId,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: typeRooms.map((tr) => DropdownMenuItem(value: tr.typeRoomId, child: Text(tr.typeRoom))).toList(),
                  onChanged: (val) => setModalState(() => selectedTypeRoomId = val),
                ),
                const SizedBox(height: 12),
                _buildFieldLabel('URL Hình ảnh phòng'),
                const SizedBox(height: 4),
                TextField(
                  controller: imageController,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9462FF)),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên phòng')));
                  return;
                }

                final updatedRoom = RoomModel(
                  roomId: isEdit ? room.roomId : roomIdController.text.trim(),
                  nameRoom: name,
                  imageUrl: imageController.text.trim().isNotEmpty ? imageController.text.trim() : null,
                  status: room?.status ?? 'Trống',
                  hotel: hotels.firstWhere((h) => h.hotelId == selectedHotelId,
                      orElse: () => HotelModel(hotelId: selectedHotelId ?? '', name: '', address: '')),
                  typeRoom: typeRooms.firstWhere((tr) => tr.typeRoomId == selectedTypeRoomId,
                      orElse: () => TypeRoomModel(typeRoomId: selectedTypeRoomId ?? '', typeRoom: '')),
                );

                final notifier = ref.read(roomListProvider.notifier);
                final success = isEdit
                    ? await notifier.updateRoom(room.roomId, updatedRoom)
                    : await notifier.createRoom(updatedRoom);

                if (mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Thành công' : 'Thất bại')),
                  );
                }
              },
              child: Text(isEdit ? 'Lưu' : 'Tạo mới', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String roomId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Quyết định này sẽ xóa phòng khỏi hệ thống. Bạn có chắc chắn không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final errorMsg = await ref.read(roomListProvider.notifier).deleteRoom(roomId);
              if (mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMsg == null ? 'Đã xóa phòng thành công' : 'Xóa thất bại: $errorMsg')),
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
