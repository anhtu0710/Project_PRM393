// lib/providers/admin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_stats_model.dart';
import '../models/admin_user_model.dart';
import '../services/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((_) => AdminService());

// Danh sách tài khoản. Gọi ref.invalidate(adminUsersProvider) để tải lại.
final adminUsersProvider =
    FutureProvider.autoDispose<List<AdminUserModel>>((ref) {
  return ref.read(adminServiceProvider).getUsers();
});

// Thống kê theo khoảng: 'day' | 'week' | 'month'
final adminStatsProvider =
    FutureProvider.autoDispose.family<AdminStatsModel, String>((ref, period) {
  return ref.read(adminServiceProvider).getStats(period);
});
