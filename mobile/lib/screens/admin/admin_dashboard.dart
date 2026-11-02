// lib/screens/admin/admin_dashboard.dart
// Phụ trách: TV1 — Dashboard thống kê: doanh thu, booking, tỉ lệ lấp phòng, top phòng

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../models/admin_stats_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../customer/booking/booking_ui.dart'; // formatVND, statusInfo

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  String _period = 'day'; // day = 7 ngày, week = 8 tuần, month = 6 tháng

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final asyncStats = ref.watch(adminStatsProvider(_period));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Quản lý người dùng',
            onPressed: () => context.push('/admin/users'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatsProvider(_period));
          await ref.read(adminStatsProvider(_period).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Text(
              'Xin chào, ${user?.fullName ?? 'Admin'}',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text('Tình hình kinh doanh GenzCinema Hotel',
                style: TextStyle(color: AppTheme.textGray)),
            const SizedBox(height: 16),

            // Chọn khoảng thời gian
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'day', label: Text('7 ngày')),
                ButtonSegment(value: 'week', label: Text('8 tuần')),
                ButtonSegment(value: 'month', label: Text('6 tháng')),
              ],
              selected: {_period},
              onSelectionChanged: (value) => setState(() => _period = value.first),
            ),
            const SizedBox(height: 16),

            asyncStats.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text(AdminService.errorMessage(e, 'Không tải được thống kê'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textGray)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(adminStatsProvider(_period)),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (stats) => _StatsContent(stats: stats),
            ),

            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.manage_accounts,
              label: 'Quản lý người dùng',
              onTap: () => context.push('/admin/users'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toàn bộ số liệu ──────────────────────────────────────────────────────────

class _StatsContent extends StatelessWidget {
  final AdminStatsModel stats;

  const _StatsContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 4 ô số liệu
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Doanh thu',
                value: formatVND(s.totalRevenue),
                icon: Icons.payments_outlined,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Booking',
                value: '${s.totalBookings}',
                icon: Icons.book_online_outlined,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Lấp phòng',
                value: '${s.occupancyRate.toStringAsFixed(1)}%',
                icon: Icons.hotel_outlined,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Người dùng',
                value: '${s.totalUsers}',
                icon: Icons.people_outline,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Biểu đồ doanh thu
        _Section(
          title: 'Doanh thu',
          subtitle: 'Chỉ tính booking đã hoàn thành',
          child: SizedBox(height: 220, child: _RevenueChart(points: s.revenueChart)),
        ),
        const SizedBox(height: 16),

        // Booking theo trạng thái
        _Section(
          title: 'Booking theo trạng thái',
          subtitle: 'Tổng ${s.totalBookings} booking trong khoảng này',
          child: Column(
            children: [
              for (final entry in s.statusCounts.entries)
                _StatusRow(
                  status: entry.key,
                  count: entry.value,
                  total: s.totalBookings,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Top phòng
        _Section(
          title: 'Phòng được đặt nhiều nhất',
          subtitle: 'Không tính booking đã huỷ hoặc bị từ chối',
          child: s.topRooms.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Chưa có booking trong khoảng này',
                      style: TextStyle(color: AppTheme.textGray)),
                )
              : Column(
                  children: [
                    for (int i = 0; i < s.topRooms.length; i++)
                      _TopRoomRow(rank: i + 1, room: s.topRooms[i]),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── Biểu đồ cột doanh thu ────────────────────────────────────────────────────

class _RevenueChart extends StatelessWidget {
  final List<ChartPointModel> points;

  const _RevenueChart({required this.points});

  // 1200000 -> "1.2tr", 300000 -> "300k"
  String _shortMoney(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}tr';
    if (v >= 1000) return '${(v / 1000).round()}k';
    return v.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    // Trục dọc cao hơn cột lớn nhất 20%, làm tròn lên bội số 100.000
    double maxRevenue = 0;
    for (final p in points) {
      if (p.revenue > maxRevenue) maxRevenue = p.revenue;
    }
    final double maxY =
        maxRevenue == 0 ? 400000 : (maxRevenue * 1.2 / 100000).ceil() * 100000;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0xFFEDE7FF), strokeWidth: 1),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppTheme.textPrimary,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              formatVND(rod.toY),
              const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(_shortMoney(value),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textGray)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(points[i].label,
                      style: const TextStyle(fontSize: 10, color: AppTheme.textGray)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].revenue,
                  width: 16,
                  color: AppTheme.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Các mảnh giao diện nhỏ ───────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Section({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String status;
  final int count;
  final int total;

  const _StatusRow({required this.status, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final (label, color) = statusInfo(status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : count / total,
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.12),
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text('$count',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _TopRoomRow extends StatelessWidget {
  final int rank;
  final TopRoomModel room;

  const _TopRoomRow({required this.rank, required this.room});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: rank == 1
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.12),
            child: Text('$rank',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: rank == 1 ? Colors.white : AppTheme.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.roomName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(room.hotelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
              ],
            ),
          ),
          Text('${room.bookingCount} lượt',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: AppTheme.textGray),
        onTap: onTap,
      ),
    );
  }
}
