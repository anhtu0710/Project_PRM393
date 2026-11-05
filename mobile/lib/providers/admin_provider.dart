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

class StatsQuery {
  final String? period;
  final DateTime? startDate;
  final DateTime? endDate;

  const StatsQuery({this.period, this.startDate, this.endDate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatsQuery &&
          period == other.period &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => Object.hash(period, startDate, endDate);
}

// Thống kê theo khoảng: period hoặc tùy chọn startDate & endDate
final adminStatsProvider =
    FutureProvider.autoDispose.family<AdminStatsModel, StatsQuery>((ref, query) {
  return ref.read(adminServiceProvider).getStats(
        period: query.period,
        startDate: query.startDate,
        endDate: query.endDate,
      );
});
