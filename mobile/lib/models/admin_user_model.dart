// lib/models/admin_user_model.dart
// 1 tài khoản trong màn Quản lý người dùng (dữ liệu từ GET /admin/users)

class AdminUserModel {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String roleId;   // ADMIN / STAFF / CUSTOMER
  final String roleName; // Administrator / Staff / Customer
  final bool locked;     // true = đã bị khoá

  const AdminUserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.roleId,
    required this.roleName,
    required this.locked,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as Map<String, dynamic>?;
    return AdminUserModel(
      userId:   json['userId']   ?? '',
      fullName: json['fullName'] ?? '',
      email:    json['email']    ?? '',
      phone:    json['phone']    ?? '',
      roleId:   role?['roleId']   ?? '',
      roleName: role?['roleName'] ?? '',
      locked:   json['locked']   ?? false,
    );
  }
}
