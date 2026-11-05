package genZ.PRM393GenZ.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

// Dữ liệu trả về cho màn Admin Dashboard
@Data
public class AdminStatsResponse {
    private String period;               // day | week | month

    private BigDecimal totalRevenue;     // tổng doanh thu (booking COMPLETED) trong khoảng
    private int totalBookings;           // số booking có giờ nhận phòng trong khoảng
    private double occupancyRate;        // tỉ lệ lấp phòng, đơn vị %
    private long totalRooms;             // tổng số phòng
    private long totalUsers;             // tổng số tài khoản

    private List<ChartPoint> revenueChart;    // mỗi phần tử là 1 cột của biểu đồ
    private Map<String, Integer> statusCounts; // VD: {"PENDING": 3, "COMPLETED": 5, ...}
    private List<TopRoom> topRooms;           // 5 phòng được đặt nhiều nhất
}
