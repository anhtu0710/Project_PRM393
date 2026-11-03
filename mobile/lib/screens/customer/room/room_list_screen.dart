// lib/screens/customer/room/room_list_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../models/room_model.dart';
import '../../../providers/room_provider.dart';
import '../../../widgets/app_bottom_nav_bar.dart';

class RoomListScreen extends ConsumerStatefulWidget {
  final String? typeFilter;
  const RoomListScreen({super.key, this.typeFilter});

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedTypeId;
  String? _selectedHotelId;
  String? _selectedPriceRange; // 'low' | 'high' | null
  DateTime? _checkIn;
  DateTime? _checkOut;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _selectedTypeId = widget.typeFilter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadRooms();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _reloadRooms() {
    ref.read(roomListProvider.notifier).loadRooms(
          keyword: _searchQuery.isEmpty ? null : _searchQuery,
          hotelId: _selectedHotelId,
          typeRoomId: _selectedTypeId,
          minPrice: _selectedPriceRange == 'high' ? 100000 : null,
          maxPrice: _selectedPriceRange == 'low' ? 99999 : null,
          checkIn: _checkIn,
          checkOut: _checkOut,
        );
  }

  List<RoomModel> _filterRooms(List<RoomModel> rooms) {
    var result = rooms;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((r) =>
              r.nameRoom.toLowerCase().contains(q) ||
              (r.typeRoom?.typeRoom.toLowerCase().contains(q) ?? false) ||
              (r.hotel?.address.toLowerCase().contains(q) ?? false) ||
              (r.hotel?.name.toLowerCase().contains(q) ?? false))
          .toList();
    }

    if (_selectedTypeId != null) {
      result = result
          .where((r) => r.typeRoom?.typeRoomId == _selectedTypeId)
          .toList();
    }

    if (_selectedHotelId != null) {
      result =
          result.where((r) => r.hotel?.hotelId == _selectedHotelId).toList();
    }

    if (_selectedPriceRange != null) {
      result = result.where((r) {
        final price = r.typeRoom?.pricePerHour ?? 0;
        return _selectedPriceRange == 'low' ? price < 100000 : price >= 100000;
      }).toList();
    }

    return result;
  }

  bool get _hasActiveFilter =>
      _selectedTypeId != null ||
      _selectedHotelId != null ||
      _selectedPriceRange != null ||
      _checkIn != null;

  void _clearAllFilters() {
    setState(() {
      _selectedTypeId = null;
      _selectedHotelId = null;
      _selectedPriceRange = null;
      _checkIn = null;
      _checkOut = null;
    });
    _reloadRooms();
  }

  Future<void> _pickAvailability() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _checkIn ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_checkIn ?? now),
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          _checkOut ?? now.add(const Duration(hours: 2))),
    );
    if (end == null || !mounted) return;

    final checkIn =
        DateTime(date.year, date.month, date.day, start.hour, start.minute);
    var checkOut =
        DateTime(date.year, date.month, date.day, end.hour, end.minute);
    if (!checkOut.isAfter(checkIn)) {
      checkOut = checkOut.add(const Duration(days: 1));
    }
    setState(() {
      _checkIn = checkIn;
      _checkOut = checkOut;
    });
    _reloadRooms();
  }

  void _showBranchFilter(List<RoomModel> rooms) {
    final hotels = <String, String>{};
    for (final r in rooms) {
      if (r.hotel != null) hotels[r.hotel!.hotelId] = r.hotel!.name;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(
        title: 'Chi Nhánh GenZ Cinema',
        options: [
          const _FilterOption(value: null, label: 'Tất cả chi nhánh'),
          ...hotels.entries
              .map((e) => _FilterOption(value: e.key, label: e.value)),
        ],
        selected: _selectedHotelId,
        onSelect: (v) {
          setState(() => _selectedHotelId = v);
          _reloadRooms();
        },
      ),
    );
  }

  void _showTypeFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(
        title: 'Loại Phòng Box Chủ Đề',
        options: const [
          _FilterOption(value: null, label: 'Tất cả loại phòng'),
          _FilterOption(value: 'QUEEN', label: 'Phòng Queen  •  96k/h'),
          _FilterOption(value: 'KING', label: 'Phòng King (PC Couple)  •  106k/h'),
          _FilterOption(value: 'FOOTBALL', label: 'Football Box  •  106k/h'),
          _FilterOption(value: 'GAMING', label: 'Gaming Box (PC Couple)  •  106k/h'),
          _FilterOption(value: 'HOIAN', label: 'Hội An Box  •  96k/h'),
          _FilterOption(value: 'HONGKONG', label: 'HongKong Box  •  96k/h'),
          _FilterOption(value: 'MARVEL', label: 'Marvel Box  •  96k/h'),
          _FilterOption(value: 'NATRA', label: 'Natra Box  •  96k/h'),
          _FilterOption(value: 'SAMURAI', label: 'Samurai Box  •  96k/h'),
          _FilterOption(value: 'ANIME', label: 'Anime Box  •  96k/h'),
          _FilterOption(value: 'AQUAMAN', label: 'Aquaman Box  •  96k/h'),
          _FilterOption(value: 'AVATAR', label: 'Avatar Box  •  96k/h'),
          _FilterOption(value: 'AVENGER', label: 'Avenger Box  •  96k/h'),
          _FilterOption(value: 'SAKURA', label: 'Sakura Box  •  96k/h'),
          _FilterOption(value: 'TEDDY', label: 'Teddy Box  •  96k/h'),
        ],
        selected: _selectedTypeId,
        onSelect: (v) {
          setState(() => _selectedTypeId = v);
          _reloadRooms();
        },
      ),
    );
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(
        title: 'Mức Giá Theo Giờ',
        options: const [
          _FilterOption(value: null, label: 'Tất cả mức giá'),
          _FilterOption(value: 'low', label: 'Dưới 100k/h  (96k/h)'),
          _FilterOption(value: 'high', label: 'Từ 100k/h  (106k/h)'),
        ],
        selected: _selectedPriceRange,
        onSelect: (v) {
          setState(() => _selectedPriceRange = v);
          _reloadRooms();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomListProvider);
    final filtered = _filterRooms(roomState.rooms);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFilterRow(roomState.rooms),
            if (_hasActiveFilter) _buildActiveFilterBar(),
            Expanded(
              child: roomState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppTheme.primary)))
                  : roomState.error != null
                      ? _buildError(roomState.error!)
                      : filtered.isEmpty
                          ? _buildEmpty()
                          : _buildRoomGrid(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) {
            setState(() => _searchQuery = v);
            _searchDebounce?.cancel();
            _searchDebounce =
                Timer(const Duration(milliseconds: 350), _reloadRooms);
          },
          decoration: InputDecoration(
            hintText: 'Tìm kiếm phòng, chi nhánh...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon:
                Icon(Icons.search, color: Colors.grey.shade400, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(List<RoomModel> allRooms) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(
                    label: 'Chi nhánh',
                    active: _selectedHotelId != null,
                    onTap: () => _showBranchFilter(allRooms),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'Loại phòng',
                    active: _selectedTypeId != null,
                    onTap: _showTypeFilter,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'Mức giá',
                    active: _selectedPriceRange != null,
                    onTap: _showPriceFilter,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'Giờ trống',
                    active: _checkIn != null,
                    onTap: _pickAvailability,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _hasActiveFilter ? _clearAllFilters : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: _hasActiveFilter ? AppTheme.primaryGradient : null,
                color: _hasActiveFilter ? null : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Icon(
                _hasActiveFilter ? Icons.filter_alt : Icons.tune,
                color: _hasActiveFilter ? Colors.white : AppTheme.textGray,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: active ? AppTheme.primaryGradient : null,
          color: active ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? Colors.transparent : AppTheme.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: active ? Colors.white : AppTheme.textPrimary,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
            const SizedBox(width: 4),
            Icon(
              active ? Icons.check : Icons.keyboard_arrow_down,
              size: 14,
              color: active ? Colors.white : AppTheme.textGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterBar() {
    final parts = <String>[];
    if (_selectedTypeId != null) parts.add(_selectedTypeId!);
    if (_selectedHotelId != null) parts.add('1 chi nhánh');
    if (_selectedPriceRange != null) {
      parts.add(_selectedPriceRange == 'low' ? '< 100k/h' : '≥ 100k/h');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text('Đang lọc: ${parts.join(' · ')}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
          ),
          GestureDetector(
            onTap: _clearAllFilters,
            child: const Text('Xóa tất cả',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomGrid(List<RoomModel> rooms) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: rooms.length,
      itemBuilder: (context, index) => _buildRoomCard(context, rooms[index]),
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomModel room) {
    final typeLabel = room.typeRoom?.typeRoom ?? 'Cinema Box';
    final hotelName = room.hotel?.name ?? 'GenZ Cinema';
    final price = room.typeRoom?.pricePerHour;
    final priceText =
        price != null ? '${(price / 1000).toStringAsFixed(0)}k/h' : '';
    final isAvailable = room.status?.toLowerCase() == 'trống' ||
        room.status?.toLowerCase() == 'available';

    return GestureDetector(
      onTap: () => context.push('/rooms/${room.roomId}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  room.imageUrl != null && room.imageUrl!.isNotEmpty
                      ? Image.network(
                          room.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                  // Status Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isAvailable ? AppTheme.success : AppTheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            room.status ?? 'Trống',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.nameRoom,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    typeLabel,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: AppTheme.primary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          hotelName,
                          style: const TextStyle(fontSize: 10, color: AppTheme.textGray),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppTheme.primaryGradient.createShader(bounds),
                        child: Text(
                          priceText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: AppTheme.goldAccent),
                          const SizedBox(width: 2),
                          Text(
                            room.averageRating > 0
                                ? room.averageRating.toStringAsFixed(1)
                                : '5.0',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3E8FF), Color(0xFFE0D0F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.bedroom_parent_outlined, size: 36, color: AppTheme.primary),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Không thể tải danh sách phòng',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _reloadRooms,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _hasActiveFilter
                ? 'Không có phòng nào phù hợp'
                : 'Không tìm thấy phòng nào',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          if (_hasActiveFilter) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _clearAllFilters,
              child: const Text('Xóa bộ lọc',
                  style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterOption {
  final String? value;
  final String label;
  const _FilterOption({required this.value, required this.label});
}

class _FilterSheet extends StatefulWidget {
  final String title;
  final List<_FilterOption> options;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _FilterSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _current;

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      widget.options.map((opt) => _buildOption(opt)).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSelect(_current);
                  Navigator.pop(context);
                },
                child: const Text('Áp dụng',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(_FilterOption opt) {
    final isSelected = _current == opt.value;
    return InkWell(
      onTap: () => setState(() => _current = opt.value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(opt.label,
                  style: TextStyle(
                      fontSize: 14,
                      color:
                          isSelected ? AppTheme.primary : AppTheme.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal)),
            ),
            if (isSelected)
              ShaderMask(
                shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                child: const Icon(Icons.check_circle,
                    color: Colors.white, size: 20),
              )
            else
              Icon(Icons.circle_outlined,
                  color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }
}
