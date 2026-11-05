// lib/screens/customer/profile/customer_profile_screen.dart
// Phụ trách: Màn hình Hồ sơ Cá nhân Khách hàng (Customer Profile)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../widgets/app_bottom_nav_bar.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isEditing = false;
  String _initialName = '';
  String _initialEmail = '';
  String _initialPhone = '';

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _initialName = user?.fullName ?? '';
    _initialEmail = user?.email ?? '';
    _initialPhone = user?.phone ?? '';

    _nameController = TextEditingController(text: _initialName);
    _emailController = TextEditingController(text: _initialEmail);
    _phoneController = TextEditingController(text: _initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF4B5563)),
    );
  }

  void _startEditing(UserModel? user) {
    setState(() {
      _initialName = _nameController.text.trim();
      _initialEmail = _emailController.text.trim();
      _initialPhone = _phoneController.text.trim();
      _isEditing = true;
    });
  }

  void _handleCancel() {
    final hasChanges = _nameController.text.trim() != _initialName ||
        _emailController.text.trim() != _initialEmail ||
        _phoneController.text.trim() != _initialPhone;

    if (hasChanges) {
      showDialog(
        context: context,
        builder: (dialogCtx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded, size: 32, color: Colors.amber.shade800),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Hủy chỉnh sửa?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bạn có những thay đổi chưa được lưu. Bạn có chắc chắn muốn hủy bỏ không?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Tiếp tục sửa',
                            style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          setState(() {
                            _nameController.text = _initialName;
                            _emailController.text = _initialEmail;
                            _phoneController.text = _initialPhone;
                            _isEditing = false;
                          });
                        },
                        child: const Text('Hủy thay đổi',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _syncControllersWithUser(UserModel? user) {
    if (!_isEditing && user != null) {
      if (_nameController.text != user.fullName) {
        _nameController.text = user.fullName;
        _initialName = user.fullName;
      }
      if (_emailController.text != user.email) {
        _emailController.text = user.email;
        _initialEmail = user.email;
      }
      if (_phoneController.text != (user.phone ?? '')) {
        _phoneController.text = user.phone ?? '';
        _initialPhone = user.phone ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    _syncControllersWithUser(user);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: const Text(
            'Hồ sơ Cá nhân',
            style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Profile Avatar Header ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName.substring(0, 1).toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.fullName ?? 'Thành viên GenZ Cinema',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? 'customer@genz.test',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, size: 14, color: Colors.amberAccent),
                        SizedBox(width: 6),
                        Text(
                          'Thành Viên Thân Thiết GenZ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Form Chỉnh sửa Thông tin ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'THÔNG TIN TÀI KHOẢN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.8,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        icon: Icon(
                          _isEditing ? Icons.close : Icons.edit,
                          size: 16,
                          color: _isEditing ? Colors.red : AppTheme.primary,
                        ),
                        label: Text(
                          _isEditing ? 'Hủy' : 'Chỉnh sửa',
                          style: TextStyle(
                            color: _isEditing ? Colors.red : AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () {
                          if (_isEditing) {
                            _handleCancel();
                          } else {
                            _startEditing(user);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildFieldLabel('Họ và tên'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _nameController,
                    readOnly: !_isEditing,
                    decoration: InputDecoration(
                      filled: !_isEditing,
                      fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildFieldLabel('Email'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _emailController,
                    readOnly: !_isEditing,
                    decoration: InputDecoration(
                      filled: !_isEditing,
                      fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildFieldLabel('Số điện thoại'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _phoneController,
                    readOnly: !_isEditing,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      filled: !_isEditing,
                      fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.save_rounded, color: Colors.white),
                        label: const Text(
                          'Lưu thay đổi',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () async {
                          final currentUser = ref.read(authProvider).user;
                          if (currentUser == null) return;

                          final currentName = _nameController.text.trim();
                          final currentEmail = _emailController.text.trim();
                          final currentPhone = _phoneController.text.trim();

                          final hasChanges = currentName != _initialName ||
                              currentEmail != _initialEmail ||
                              currentPhone != _initialPhone;

                          if (!hasChanges) {
                            setState(() {
                              _isEditing = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thông tin của bạn vẫn giữ nguyên'),
                                backgroundColor: AppTheme.primary,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          final success = await ref.read(authProvider.notifier).updateProfile(
                                userId: currentUser.userId,
                                fullName: currentName,
                                email: currentEmail,
                                phone: currentPhone,
                              );
                          if (mounted) {
                            if (success) {
                              setState(() {
                                _initialName = currentName;
                                _initialEmail = currentEmail;
                                _initialPhone = currentPhone;
                                _isEditing = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã cập nhật thông tin cá nhân thành công!'),
                                  backgroundColor: AppTheme.primary,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else {
                              final err = ref.read(authProvider).error ?? 'Cập nhật thất bại';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(err),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Menu Lối Tắt Nhanh ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _menuItem(
                    icon: Icons.history_rounded,
                    color: Colors.purple,
                    title: 'Lịch sử đặt phòng',
                    onTap: () => context.push('/bookings'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _menuItem(
                    icon: Icons.card_giftcard_rounded,
                    color: Colors.pink,
                    title: 'Kho Voucher ưu đãi',
                    onTap: () => context.push('/vouchers'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _menuItem(
                    icon: Icons.rate_review_outlined,
                    color: Colors.amber.shade800,
                    title: 'Đánh giá trải nghiệm',
                    onTap: () => context.push('/reviews'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _menuItem(
                    icon: Icons.notifications_none_rounded,
                    color: Colors.blue,
                    title: 'Trung tâm thông báo',
                    onTap: () => context.push('/notifications'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Đổi Mật Khẩu ──────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.lock_reset_rounded, color: Colors.orange.shade800),
                ),
                title: const Text('Đổi mật khẩu tài khoản',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                onTap: () => _showChangePasswordDialog(context),
              ),
            ),
            const SizedBox(height: 24),

            // ── Logout Button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Đăng xuất khỏi tài khoản',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () => _confirmLogout(context, ref),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    ),
  );
  }

  Widget _menuItem({required IconData icon, required Color color, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: AppTheme.primary),
            SizedBox(width: 10),
            Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Mật khẩu hiện tại'),
              const SizedBox(height: 4),
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Nhập mật khẩu cũ',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              _buildFieldLabel('Mật khẩu mới'),
              const SizedBox(height: 4),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Tối thiểu 6 ký tự',
                  prefixIcon: const Icon(Icons.key, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Yêu cầu đổi mật khẩu đã được xử lý thành công!'),
                ),
              );
            },
            child: const Text('Lưu mật khẩu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded, size: 32, color: Colors.red.shade700),
              ),
              const SizedBox(height: 14),
              const Text(
                'Xác nhận đăng xuất',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Hủy', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        Navigator.pop(dialogCtx);
                        ref.read(notificationListProvider.notifier).clear();
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                      child: const Text('Đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
