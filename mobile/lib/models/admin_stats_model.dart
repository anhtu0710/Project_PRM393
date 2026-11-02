// lib/models/admin_stats_model.dart
// Số liệu cho Admin Dashboard (dữ liệu từ GET /admin/stats)

class AdminStatsModel {
  final double totalRevenue;
  final int totalBookings;
  final double occupancyRate; // đơn vị %
  final int totalRooms;
  final int totalUsers;
  final List<ChartPointModel> revenueChart;
  final Map<String, int> statusCounts; // VD: {"PENDING": 3, ...}
  final List<TopRoomModel> topRooms;

  const AdminStatsModel({
    required this.totalRevenue,
    required this.totalBookings,
    required this.occupancyRate,
    required this.totalRooms,
    required this.totalUsers,
    required this.revenueChart,
    required this.statusCounts,
    required this.topRooms,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    final chart = (json['revenueChart'] as List<dynamic>? ?? [])
        .map((e) => ChartPointModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final counts = <String, int>{};
    final rawCounts = json['statusCounts'] as Map<String, dynamic>? ?? {};
    rawCounts.forEach((key, value) => counts[key] = (value as num).toInt());

    final rooms = (json['topRooms'] as List<dynamic>? ?? [])
        .map((e) => TopRoomModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return AdminStatsModel(
      totalRevenue:  (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      totalBookings: (json['totalBookings'] as num?)?.toInt() ?? 0,
      occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? 0,
      totalRooms:    (json['totalRooms'] as num?)?.toInt() ?? 0,
      totalUsers:    (json['totalUsers'] as num?)?.toInt() ?? 0,
      revenueChart:  chart,
      statusCounts:  counts,
      topRooms:      rooms,
    );
  }
}

// 1 cột của biểu đồ doanh thu
class ChartPointModel {
  final String label;
  final double revenue;

  const ChartPointModel({required this.label, required this.revenue});

  factory ChartPointModel.fromJson(Map<String, dynamic> json) {
    return ChartPointModel(
      label:   json['label'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

// 1 phòng trong danh sách "đặt nhiều nhất"
class TopRoomModel {
  final String roomId;
  final String roomName;
  final String hotelName;
  final int bookingCount;

  const TopRoomModel({
    required this.roomId,
    required this.roomName,
    required this.hotelName,
    required this.bookingCount,
  });

  factory TopRoomModel.fromJson(Map<String, dynamic> json) {
    return TopRoomModel(
      roomId:       json['roomId'] ?? '',
      roomName:     json['roomName'] ?? '',
      hotelName:    json['hotelName'] ?? '',
      bookingCount: (json['bookingCount'] as num?)?.toInt() ?? 0,
    );
  }
}
