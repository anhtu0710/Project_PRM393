package genZ.PRM393GenZ.service;

import genZ.PRM393GenZ.constant.BookingStatus;
import genZ.PRM393GenZ.dto.AdminStatsResponse;
import genZ.PRM393GenZ.dto.ChartPoint;
import genZ.PRM393GenZ.dto.TopRoom;
import genZ.PRM393GenZ.entity.Booking;
import genZ.PRM393GenZ.entity.Room;
import genZ.PRM393GenZ.repository.BookingRepository;
import genZ.PRM393GenZ.repository.RoomRepository;
import genZ.PRM393GenZ.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class StatsService {

    private final BookingRepository bookingRepository;
    private final RoomRepository roomRepository;
    private final UserRepository userRepository;

    public AdminStatsResponse getStats(String period) {
        return getStats(null, null, period);
    }

    public AdminStatsResponse getStats(LocalDate startDate, LocalDate endDate, String period) {
        LocalDate today = LocalDate.now();
        LocalDate rangeStart;
        LocalDate rangeEnd;

        List<LocalDate> columnStarts = new ArrayList<>();
        List<String> labels = new ArrayList<>();

        if (startDate != null && endDate != null) {
            rangeStart = startDate;
            rangeEnd = endDate.plusDays(1); // tính đến hết ngày kết thúc

            long daysBetween = Duration.between(rangeStart.atStartOfDay(), rangeEnd.atStartOfDay()).toDays();
            if (daysBetween > 90) {
                LocalDate current = rangeStart.withDayOfMonth(1);
                while (!current.isAfter(endDate)) {
                    columnStarts.add(current);
                    labels.add("T" + current.getMonthValue() + "/" + String.valueOf(current.getYear()).substring(2));
                    current = current.plusMonths(1);
                }
            } else if (daysBetween > 14) {
                LocalDate current = rangeStart.with(DayOfWeek.MONDAY);
                while (!current.isAfter(endDate)) {
                    columnStarts.add(current);
                    labels.add(current.getDayOfMonth() + "/" + current.getMonthValue());
                    current = current.plusWeeks(1);
                }
            } else {
                LocalDate current = rangeStart;
                while (!current.isAfter(endDate)) {
                    columnStarts.add(current);
                    labels.add(current.getDayOfMonth() + "/" + current.getMonthValue());
                    current = current.plusDays(1);
                }
            }
            if (columnStarts.isEmpty()) {
                columnStarts.add(rangeStart);
                labels.add(rangeStart.getDayOfMonth() + "/" + rangeStart.getMonthValue());
            }
        } else {
            rangeEnd = today.plusDays(1);
            if ("month".equals(period)) {
                LocalDate firstDayOfMonth = today.withDayOfMonth(1);
                for (int i = 5; i >= 0; i--) {
                    LocalDate start = firstDayOfMonth.minusMonths(i);
                    columnStarts.add(start);
                    labels.add("T" + start.getMonthValue());
                }
            } else if ("week".equals(period)) {
                LocalDate monday = today.with(DayOfWeek.MONDAY);
                for (int i = 7; i >= 0; i--) {
                    LocalDate start = monday.minusWeeks(i);
                    columnStarts.add(start);
                    labels.add(start.getDayOfMonth() + "/" + start.getMonthValue());
                }
            } else {
                period = "day";
                for (int i = 6; i >= 0; i--) {
                    LocalDate start = today.minusDays(i);
                    columnStarts.add(start);
                    labels.add(start.getDayOfMonth() + "/" + start.getMonthValue());
                }
            }
            rangeStart = columnStarts.get(0);
        }

        // 2. Chuẩn bị chỗ cộng dồn
        BigDecimal[] revenueByColumn = new BigDecimal[columnStarts.size()];
        Arrays.fill(revenueByColumn, BigDecimal.ZERO);
        BigDecimal totalRevenue = BigDecimal.ZERO;
        int totalBookings = 0;
        double soldHours = 0; // tổng số giờ phòng đã bán

        // Giữ đúng thứ tự 6 trạng thái để app hiện đẹp
        Map<String, Integer> statusCounts = new LinkedHashMap<>();
        statusCounts.put(BookingStatus.PENDING, 0);
        statusCounts.put(BookingStatus.CONFIRMED, 0);
        statusCounts.put(BookingStatus.CHECKED_IN, 0);
        statusCounts.put(BookingStatus.COMPLETED, 0);
        statusCounts.put(BookingStatus.CANCELLED, 0);
        statusCounts.put(BookingStatus.REJECTED, 0);

        Map<String, Integer> countByRoom = new HashMap<>(); // roomId → số lượt đặt
        Map<String, Room> roomById = new HashMap<>();

        // 3. Duyệt toàn bộ booking 1 lần
        for (Booking b : bookingRepository.findAll()) {
            if (b.getCheckIn() == null) continue;
            LocalDate day = b.getCheckIn().toLocalDate();
            if (day.isBefore(rangeStart) || !day.isBefore(rangeEnd)) continue; // ngoài khoảng đang xem

            String status = b.getStatus();
            totalBookings++;
            statusCounts.put(status, statusCounts.getOrDefault(status, 0) + 1);

            // Doanh thu: chỉ booking đã hoàn thành (đã thu tiền tại quầy)
            if (BookingStatus.COMPLETED.equals(status) && b.getTotalPrice() != null) {
                int column = findColumn(columnStarts, day);
                revenueByColumn[column] = revenueByColumn[column].add(b.getTotalPrice());
                totalRevenue = totalRevenue.add(b.getTotalPrice());
            }

            // Giờ đã bán: booking đã xác nhận, đang ở hoặc đã xong
            if (BookingStatus.CONFIRMED.equals(status)
                    || BookingStatus.CHECKED_IN.equals(status)
                    || BookingStatus.COMPLETED.equals(status)) {
                if (b.getCheckOut() != null) {
                    soldHours += Duration.between(b.getCheckIn(), b.getCheckOut()).toMinutes() / 60.0;
                }
            }

            // Phòng được đặt nhiều: bỏ qua booking đã huỷ / bị từ chối
            if (!BookingStatus.CANCELLED.equals(status)
                    && !BookingStatus.REJECTED.equals(status)
                    && b.getRoom() != null) {
                String roomId = b.getRoom().getRoomId();
                countByRoom.put(roomId, countByRoom.getOrDefault(roomId, 0) + 1);
                roomById.put(roomId, b.getRoom());
            }
        }

        // 4. Tỉ lệ lấp phòng = giờ đã bán / (số phòng × số giờ trong khoảng)
        long totalRooms = roomRepository.count();
        double hoursInRange = Duration.between(rangeStart.atStartOfDay(), rangeEnd.atStartOfDay()).toHours();
        double occupancyRate = 0;
        if (totalRooms > 0 && hoursInRange > 0) {
            occupancyRate = soldHours * 100 / (totalRooms * hoursInRange);
            occupancyRate = Math.round(occupancyRate * 10) / 10.0; // làm tròn 1 chữ số
        }

        // 5. Biểu đồ doanh thu
        List<ChartPoint> chart = new ArrayList<>();
        for (int i = 0; i < columnStarts.size(); i++) {
            chart.add(new ChartPoint(labels.get(i), revenueByColumn[i]));
        }

        // 6. Top 5 phòng
        List<TopRoom> topRooms = new ArrayList<>();
        for (String roomId : countByRoom.keySet()) {
            Room room = roomById.get(roomId);
            String hotelName = room.getHotel() != null ? room.getHotel().getName() : "";
            topRooms.add(new TopRoom(roomId, room.getNameRoom(), hotelName, countByRoom.get(roomId)));
        }
        topRooms.sort((a, b) -> b.getBookingCount() - a.getBookingCount()); // nhiều nhất lên đầu
        if (topRooms.size() > 5) {
            topRooms = topRooms.subList(0, 5);
        }

        // 7. Gói kết quả
        AdminStatsResponse result = new AdminStatsResponse();
        result.setPeriod(period != null ? period : "custom");
        result.setTotalRevenue(totalRevenue);
        result.setTotalBookings(totalBookings);
        result.setOccupancyRate(occupancyRate);
        result.setTotalRooms(totalRooms);
        result.setTotalUsers(userRepository.count());
        result.setRevenueChart(chart);
        result.setStatusCounts(statusCounts);
        result.setTopRooms(topRooms);
        return result;
    }

    // Booking ngày "day" rơi vào cột nào (cột cuối cùng có ngày bắt đầu <= day)
    private int findColumn(List<LocalDate> columnStarts, LocalDate day) {
        for (int i = columnStarts.size() - 1; i >= 0; i--) {
            if (!day.isBefore(columnStarts.get(i))) {
                return i;
            }
        }
        return 0;
    }
}
