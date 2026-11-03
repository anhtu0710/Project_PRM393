// lib/services/auth_service.dart
// Đăng nhập / đăng ký / quên mật khẩu — đọc ghi thẳng database SQLite trong máy.
// Lỗi được ném ra dưới dạng câu tiếng Việt (String), màn hình hiện thẳng câu đó.

import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  // ─── Login ────────────────────────────────────────────────────────────

  Future<UserModel> login(String email, String password) async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT u.*, r.RoleName FROM [User] u
      LEFT JOIN Role r ON u.RoleId = r.RoleId
      WHERE u.email = ?''', [email.trim()]);

    if (rows.isEmpty ||
        rows.first['password'] != DatabaseHelper.hashPassword(password)) {
      throw 'Email hoặc mật khẩu không đúng';
    }
    final row = rows.first;
    if (row['IsLocked'] == 1) {
      throw 'Tài khoản đã bị khoá';
    }

    final user = UserModel(
      userId: row['UserId'] as String,
      fullName: row['full_name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      role: row['RoleName'] as String? ?? 'Customer',
      roleId: row['RoleId'] as String? ?? AppConfig.roleCustomer,
      token: 'offline', // không còn server nên không cần JWT thật
    );

    // Lưu người đang đăng nhập để lần sau mở app không phải đăng nhập lại
    await _storage.write(key: AppConfig.tokenKey, value: user.token);
    await _storage.write(key: AppConfig.userKey, value: jsonEncode(user.toJson()));
    return user;
  }

  // ─── Register ─────────────────────────────────────────────────────────

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String roleId,
  }) async {
    final db = await DatabaseHelper.database;

    final sameEmail = await db.query('[User]', where: 'email = ?', whereArgs: [email]);
    if (sameEmail.isNotEmpty) throw 'Email đã được sử dụng';

    final samePhone = await db.query('[User]', where: 'phone = ?', whereArgs: [phone]);
    if (samePhone.isNotEmpty) throw 'Số điện thoại đã được sử dụng';

    final role = await db.query('Role', where: 'RoleId = ?', whereArgs: [roleId]);
    if (role.isEmpty) throw 'Vai trò không tồn tại';

    await db.insert('[User]', {
      'UserId': 'U${DateTime.now().millisecondsSinceEpoch}',
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password': DatabaseHelper.hashPassword(password),
      'RoleId': roleId,
      'IsLocked': 0,
    });
  }

  // ─── Logout ───────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: AppConfig.userKey);
  }

  // ─── Quên mật khẩu ────────────────────────────────────────────────────
  // Bản offline không gửi được email: tạo mã đặt lại rồi trả về luôn,
  // màn hình sẽ tự mở trang đặt mật khẩu mới với mã này.

  Future<String> requestPasswordReset(String email) async {
    final db = await DatabaseHelper.database;
    final users = await db.query('[User]', where: 'email = ?', whereArgs: [email]);
    if (users.isEmpty) throw 'Email không tồn tại trong hệ thống';
    final userId = users.first['UserId'];

    // Xoá mã cũ của người này, tạo mã mới hết hạn sau 15 phút
    await db.delete('PasswordResetToken', where: 'UserId = ?', whereArgs: [userId]);
    final token = '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(99999)}';
    await db.insert('PasswordResetToken', {
      'token': token,
      'expiryTime': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
      'isUsed': 0,
      'UserId': userId,
    });
    return token;
  }

  // ─── Verify Token ─────────────────────────────────────────────────────

  Future<String> verifyResetToken(String token) async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT t.*, u.email FROM PasswordResetToken t
      JOIN [User] u ON t.UserId = u.UserId
      WHERE t.token = ?''', [token]);

    if (rows.isEmpty) throw 'Token không hợp lệ hoặc không tồn tại';
    final row = rows.first;
    if (row['isUsed'] == 1) {
      throw 'Token đã được sử dụng. Vui lòng yêu cầu đặt lại mật khẩu mới.';
    }
    if (DateTime.now().isAfter(DateTime.parse(row['expiryTime'] as String))) {
      throw 'Token đã hết hạn. Vui lòng yêu cầu đặt lại mật khẩu mới.';
    }
    return row['email'] as String; // trả về email
  }

  // ─── Reset Password ───────────────────────────────────────────────────

  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    if (password != confirmPassword) {
      throw 'Mật khẩu mới và xác nhận mật khẩu không khớp';
    }
    await verifyResetToken(token); // sai / hết hạn thì ném lỗi luôn

    final db = await DatabaseHelper.database;
    final rows = await db.query('PasswordResetToken', where: 'token = ?', whereArgs: [token]);
    final userId = rows.first['UserId'];

    await db.update('[User]', {'password': DatabaseHelper.hashPassword(password)},
        where: 'UserId = ?', whereArgs: [userId]);
    await db.update('PasswordResetToken', {'isUsed': 1},
        where: 'token = ?', whereArgs: [token]);
  }

  // ─── Get Current User from storage ────────────────────────────────────

  Future<UserModel?> getCurrentUser() async {
    final userJson = await _storage.read(key: AppConfig.userKey);
    if (userJson == null) return null;
    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      final saved = UserModel.fromJson(map, map['token'] ?? '');

      // Kiểm tra lại trong database: bị xoá hoặc bị khoá thì coi như đã đăng xuất,
      // còn role có thể đã bị Admin đổi nên lấy role mới nhất.
      final db = await DatabaseHelper.database;
      final rows = await db.rawQuery('''
        SELECT u.RoleId, u.IsLocked, r.RoleName FROM [User] u
        LEFT JOIN Role r ON u.RoleId = r.RoleId
        WHERE u.UserId = ?''', [saved.userId]);
      if (rows.isEmpty || rows.first['IsLocked'] == 1) {
        await logout();
        return null;
      }
      return saved.copyWith(
        roleId: rows.first['RoleId'] as String?,
        role: rows.first['RoleName'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    return await getCurrentUser() != null;
  }
}
