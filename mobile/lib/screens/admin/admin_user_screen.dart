// lib/screens/admin/admin_user_screen.dart
// Phụ trách: TV1 — Quản lý người dùng: tìm kiếm, lọc theo role, đổi role, gán chi nhánh, khoá / mở khoá

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../models/admin_user_model.dart';
import '../../models/hotel_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../services/admin_service.dart';

class AdminUserScreen extends ConsumerStatefulWidget {
  const AdminUserScreen({super.key});

  @override
  ConsumerState<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends ConsumerState<AdminUserScreen> {
  String _keyword = '';
  String _roleFilter = 'ALL'; // ALL / CUSTOMER / STAFF / ADMIN

  // Tài khoản có khớp ô tìm kiếm và bộ lọc role không
  bool _match(AdminUserModel u) {
    if (_roleFilter != 'ALL' && u.roleId != _roleFilter) return false;
    if (_keyword.isEmpty) return true;
    final k = _keyword.toLowerCase();
    return u.fullName.toLowerCase().contains(k) ||
        u.email.toLowerCase().contains(k) ||
        u.phone.contains(k);
  }

  // ── Hành động ──────────────────────────────────────────────────────────

  Future<void> _changeRole(AdminUserModel u) async {
    final newRole = u.roleId == AppConfig.roleStaff
        ? AppConfig.roleCustomer
        : AppConfig.roleStaff;
    final newName = roleLabel(newRole);
    final ok = await _confirm('Đổi role', 'Chuyển ${u.fullName} thành $newName?');
    if (!ok) return;
    await _run(
      () => ref.read(adminServiceProvider).changeRole(u.userId, newRole),
      'Đã chuyển ${u.fullName} thành $newName',
    );
  }

  Future<void> _assignHotelDialog(AdminUserModel u, List<HotelModel> hotels) async {
    String? selectedHotelId = u.hotelId;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Gán Chi Nhánh Cho ${u.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chọn cơ sở GenZ Cinema mà nhân viên này phụ trách:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedHotelId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Chọn chi nhánh'),
                items: hotels.map((h) {
                  return DropdownMenuItem<String>(
                    value: h.hotelId,
                    child: Text(h.name, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  setDialogState(() => selectedHotelId = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Bỏ gán', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () => Navigator.pop(ctx, selectedHotelId ?? ''),
              child: const Text('Lưu thay đổi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _run(
        () => ref.read(adminServiceProvider).assignHotel(u.userId, result.isEmpty ? null : result),
        'Đã cập nhật chi nhánh phụ trách cho ${u.fullName}',
      );
    }
  }

  Future<void> _toggleLock(AdminUserModel u) async {
    final lock = !u.locked;
    final ok = await _confirm(
      lock ? 'Khoá tài khoản' : 'Mở khoá tài khoản',
      lock
          ? '${u.fullName} sẽ không đăng nhập được nữa. Tiếp tục?'
          : 'Cho ${u.fullName} đăng nhập lại?',
    );
    if (!ok) return;
    await _run(
      () => ref.read(adminServiceProvider).setLocked(u.userId, lock),
      lock ? 'Đã khoá ${u.fullName}' : 'Đã mở khoá ${u.fullName}',
    );
  }

  Future<void> _run(Future<void> Function() action, String successText) async {
    try {
      await action();
      ref.invalidate(adminUsersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successText)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AdminService.errorMessage(e, 'Thao tác thất bại')),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<bool> _confirm(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final asyncUsers = ref.watch(adminUsersProvider);
    final hotelState = ref.watch(hotelListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý người dùng')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _keyword = value.trim()),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, email hoặc SĐT',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEDE7FF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEDE7FF)),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('ALL', 'Tất cả'),
                _filterChip(AppConfig.roleCustomer, 'Khách hàng'),
                _filterChip(AppConfig.roleStaff, 'Staff'),
                _filterChip(AppConfig.roleAdmin, 'Admin'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: asyncUsers.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AdminService.errorMessage(e, 'Không tải được danh sách'),
                        style: const TextStyle(color: AppTheme.textGray)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(adminUsersProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (users) {
                final shown = users.where(_match).toList();
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminUsersProvider);
                    await ref.read(adminUsersProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: shown.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return Text(
                          shown.isEmpty
                              ? 'Không có tài khoản nào khớp'
                              : '${shown.length} tài khoản',
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textGray),
                        );
                      }
                      final u = shown[i - 1];
                      return _UserCard(
                        user: u,
                        hotels: hotelState.hotels,
                        onChangeRole: () => _changeRole(u),
                        onAssignHotel: () => _assignHotelDialog(u, hotelState.hotels),
                        onToggleLock: () => _toggleLock(u),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _roleFilter == value,
        selectedColor: AppTheme.primary.withValues(alpha: 0.15),
        onSelected: (_) => setState(() => _roleFilter = value),
      ),
    );
  }
}

// ── Tên + màu của từng role ──────────────────────────────────────────────────

String roleLabel(String roleId) {
  switch (roleId) {
    case AppConfig.roleAdmin:
      return 'Admin';
    case AppConfig.roleStaff:
      return 'Staff';
    default:
      return 'Khách hàng';
  }
}

Color roleColor(String roleId) {
  switch (roleId) {
    case AppConfig.roleAdmin:
      return AppTheme.primaryDark;
    case AppConfig.roleStaff:
      return AppTheme.primary;
    default:
      return Colors.teal;
  }
}

// ── 1 thẻ tài khoản ──────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final AdminUserModel user;
  final List<HotelModel> hotels;
  final VoidCallback onChangeRole;
  final VoidCallback onAssignHotel;
  final VoidCallback onToggleLock;

  const _UserCard({
    required this.user,
    required this.hotels,
    required this.onChangeRole,
    required this.onAssignHotel,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context) {
    final u = user;
    final color = roleColor(u.roleId);
    final isAdmin = u.roleId == AppConfig.roleAdmin;
    final isStaff = u.roleId == AppConfig.roleStaff;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(u.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
                if (u.phone.isNotEmpty)
                  Text(u.phone,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _chip(roleLabel(u.roleId), color),
                    if (isStaff && u.hotelName != null && u.hotelName!.isNotEmpty)
                      _chip('Cơ sở: ${u.hotelName}', AppTheme.goldAccent),
                    if (u.locked) _chip('Đã khoá', AppTheme.error),
                  ],
                ),
              ],
            ),
          ),
          if (isAdmin)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.shield_outlined, color: AppTheme.textGray),
            )
          else
            PopupMenuButton<String>(
              tooltip: 'Thao tác',
              onSelected: (value) {
                if (value == 'role') onChangeRole();
                if (value == 'hotel') onAssignHotel();
                if (value == 'lock') onToggleLock();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'role',
                  child: Text(u.roleId == AppConfig.roleStaff
                      ? 'Chuyển thành Khách hàng'
                      : 'Chuyển thành Staff'),
                ),
                if (isStaff)
                  const PopupMenuItem(
                    value: 'hotel',
                    child: Text('Gán Chi Nhánh Phụ Trách 🏬'),
                  ),
                PopupMenuItem(
                  value: 'lock',
                  child: Text(
                    u.locked ? 'Mở khoá tài khoản' : 'Khoá tài khoản',
                    style: TextStyle(
                        color: u.locked ? AppTheme.success : AppTheme.error),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
