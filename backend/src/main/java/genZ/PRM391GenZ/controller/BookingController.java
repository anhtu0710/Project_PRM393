package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.constant.BookingStatus;
import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.Booking;
import genZ.PRM391GenZ.entity.Notification;
import genZ.PRM391GenZ.entity.PriceConfig;
import genZ.PRM391GenZ.entity.Room;
import genZ.PRM391GenZ.entity.TypeBooking;
import genZ.PRM391GenZ.entity.User;
import genZ.PRM391GenZ.entity.Voucher;
import genZ.PRM391GenZ.repository.BookingRepository;
import genZ.PRM391GenZ.repository.NotificationRepository;
import genZ.PRM391GenZ.repository.PriceConfigRepository;
import genZ.PRM391GenZ.repository.RoomRepository;
import genZ.PRM391GenZ.repository.TypeBookingRepository;
import genZ.PRM391GenZ.repository.UserRepository;
import genZ.PRM391GenZ.repository.VoucherRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.security.Principal;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/bookings")
@RequiredArgsConstructor
public class BookingController {

    private final BookingRepository bookingRepository;
    private final RoomRepository roomRepository;
    private final TypeBookingRepository typeBookingRepository;
    private final PriceConfigRepository priceConfigRepository;
    private final VoucherRepository voucherRepository;
    private final UserRepository userRepository;
    private final NotificationRepository notificationRepository;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<List<Booking>>> getAllBookings() {
        return ResponseEntity.ok(
                ApiResponse.success("Danh sách booking", bookingRepository.findAll())
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Booking>> getBookingById(@PathVariable Integer id) {
        return bookingRepository.findById(id)
                .map(b -> ResponseEntity.ok(ApiResponse.success("Thông tin booking", b)))
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<Booking>>> getBookingsByUser(@PathVariable String userId) {
        List<Booking> bookings = bookingRepository.findByUser_UserId(userId);
        return ResponseEntity.ok(ApiResponse.success("Booking của người dùng", bookings));
    }

    // ── Bảng giá ────────────────────────────────────────────────────────────
    @GetMapping("/prices")
    public ResponseEntity<ApiResponse<List<PriceConfig>>> getPrices() {
        return ResponseEntity.ok(ApiResponse.success("Bảng giá", priceConfigRepository.findAll()));
    }

    // ── Voucher ─────────────────────────────────────────────────────────────
    @GetMapping("/vouchers")
    public ResponseEntity<ApiResponse<List<Voucher>>> getVouchers() {
        List<Voucher> vouchers = voucherRepository.findByExpiryDateAfter(LocalDateTime.now());
        return ResponseEntity.ok(ApiResponse.success("Voucher khả dụng", vouchers));
    }

    @GetMapping("/vouchers/check")
    public ResponseEntity<ApiResponse<Voucher>> checkVoucher(
            @RequestParam String code, @RequestParam BigDecimal amount) {
        Voucher voucher = findValidVoucher(code, amount);
        return ResponseEntity.ok(ApiResponse.success("Voucher hợp lệ", voucher));
    }

    // ── Đặt phòng ───────────────────────────────────────────────────────────
    @PostMapping
    public ResponseEntity<ApiResponse<Booking>> createBooking(
            @RequestBody Booking booking, Principal principal) {

        // 1. Lấy user từ token
        User user = userRepository.findByEmail(principal.getName())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy tài khoản"));

        // 2. Kiểm tra dữ liệu đầu vào
        if (booking.getRoom() == null || booking.getRoom().getRoomId() == null) {
            throw new RuntimeException("Thiếu thông tin phòng");
        }
        if (booking.getTypeBooking() == null || booking.getTypeBooking().getTypeBookingId() == null) {
            throw new RuntimeException("Thiếu hình thức thuê");
        }
        if (booking.getCheckIn() == null) {
            throw new RuntimeException("Thiếu giờ nhận phòng");
        }
        if (booking.getCheckIn().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("Giờ nhận phòng phải sau thời điểm hiện tại");
        }

        Room room = roomRepository.findById(booking.getRoom().getRoomId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phòng"));

        String roomStatus = room.getStatus();
        if (!"Trống".equalsIgnoreCase(roomStatus) && !"available".equalsIgnoreCase(roomStatus)) {
            throw new RuntimeException("Phòng đang " + (roomStatus != null ? roomStatus.toLowerCase() : "bận") + ", tạm thời khóa đặt phòng!");
        }

        TypeBooking typeBooking = typeBookingRepository.findById(booking.getTypeBooking().getTypeBookingId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy hình thức thuê"));

        // 3. Tính giờ trả phòng
        LocalDateTime checkIn = booking.getCheckIn();
        LocalDateTime checkOut;
        if (typeBooking.getDurationHours() != null) {
            checkOut = checkIn.plusHours(typeBooking.getDurationHours());
        } else if (booking.getCheckOut() != null && booking.getCheckOut().isAfter(checkIn)) {
            checkOut = booking.getCheckOut();
        } else {
            throw new RuntimeException("Giờ trả phòng không hợp lệ");
        }

        // 4. Kiểm tra trùng lịch
        List<Booking> roomBookings = bookingRepository.findByRoom_RoomId(room.getRoomId());
        for (Booking other : roomBookings) {
            String status = other.getStatus();
            if (BookingStatus.CANCELLED.equals(status)
                    || BookingStatus.REJECTED.equals(status)
                    || BookingStatus.COMPLETED.equals(status)) {
                continue;
            }
            LocalDateTime otherIn = other.getCheckIn();
            LocalDateTime otherOut = other.getCheckOut();
            if (otherOut == null) {
                Integer hours = other.getTypeBooking() != null ? other.getTypeBooking().getDurationHours() : null;
                otherOut = otherIn.plusHours(hours != null ? hours : 2);
            }
            if (checkIn.isBefore(otherOut) && checkOut.isAfter(otherIn)) {
                throw new RuntimeException("Phòng đã có người đặt trong khung giờ này, vui lòng chọn giờ khác");
            }
        }

        // 5. Giá từ PriceConfig
        if (room.getTypeRoom() == null) {
            throw new RuntimeException("Phòng chưa có loại phòng, không tính được giá");
        }
        PriceConfig priceConfig = priceConfigRepository
                .findByTypeRoom_TypeRoomIdAndTypeBooking_TypeBookingId(
                        room.getTypeRoom().getTypeRoomId(), typeBooking.getTypeBookingId())
                .orElseThrow(() -> new RuntimeException("Chưa có giá cho loại phòng và combo này"));
        BigDecimal price = priceConfig.getPrice();

        // 6. Áp voucher
        BigDecimal discount = BigDecimal.ZERO;
        String voucherCode = booking.getVoucherCode();
        if (voucherCode != null && !voucherCode.isBlank()) {
            Voucher voucher = findValidVoucher(voucherCode, price);
            discount = calculateDiscount(voucher, price);
            voucherCode = voucher.getCode();
        } else {
            voucherCode = null;
        }

        // 7. Lưu booking
        booking.setUser(user);
        booking.setRoom(room);
        booking.setTypeBooking(typeBooking);
        booking.setCheckOut(checkOut);
        booking.setVoucherCode(voucherCode);
        booking.setDiscountAmount(discount);
        booking.setTotalPrice(price.subtract(discount));
        booking.setStatus(BookingStatus.PENDING);

        Booking saved = bookingRepository.save(booking);

        // 8. Tạo thông báo cho Khách hàng & Staff phụ trách chi nhánh đó
        try {
            // Thông báo cho Khách
            notificationRepository.save(Notification.builder()
                    .userId(user.getUserId())
                    .bookingId(saved.getBookingId())
                    .title("Đặt phòng thành công! 🎟️")
                    .message("Mã đơn #" + saved.getBookingId() + " tại " + room.getHotel().getName() + " - " + room.getNameRoom() + " đã được ghi nhận. Vui lòng chờ xác nhận.")
                    .read(false)
                    .build());

            // Thông báo cho tất cả Staff thuộc Chi nhánh này
            List<User> branchStaffs = userRepository.findByHotel_HotelIdAndRole_RoleId(room.getHotel().getHotelId(), "STAFF");
            if (branchStaffs.isEmpty()) {
                branchStaffs = userRepository.findByRole_RoleId("STAFF");
            }
            for (User staffUser : branchStaffs) {
                notificationRepository.save(Notification.builder()
                        .userId(staffUser.getUserId())
                        .bookingId(saved.getBookingId())
                        .title("Đơn đặt phòng MỚI cần duyệt ⚡")
                        .message("Khách hàng " + user.getFullName() + " vừa đặt phòng " + room.getNameRoom() + " tại " + room.getHotel().getName() + ".")
                        .read(false)
                        .build());
            }
        } catch (Exception ignored) {}

        return ResponseEntity.ok(ApiResponse.success("Đặt phòng thành công", saved));
    }

    // ── Khách tự huỷ booking ────────────────────────────────────────────────
    @PutMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<Booking>> cancelBooking(
            @PathVariable Integer id, Principal principal) {
        Booking booking = bookingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy booking"));

        String ownerEmail = booking.getUser() != null ? booking.getUser().getEmail() : null;
        if (ownerEmail == null || !ownerEmail.equalsIgnoreCase(principal.getName())) {
            throw new RuntimeException("Bạn không có quyền huỷ booking này");
        }

        String status = booking.getStatus();
        if (!BookingStatus.PENDING.equals(status) && !BookingStatus.CONFIRMED.equals(status)) {
            throw new RuntimeException("Chỉ huỷ được booking đang chờ duyệt hoặc đã xác nhận");
        }

        booking.setStatus(BookingStatus.CANCELLED);
        Booking updated = bookingRepository.save(booking);

        // Thông báo cho các Staff của Chi nhánh
        try {
            List<User> branchStaffs = userRepository.findByHotel_HotelIdAndRole_RoleId(updated.getRoom().getHotel().getHotelId(), "STAFF");
            if (branchStaffs.isEmpty()) {
                branchStaffs = userRepository.findByRole_RoleId("STAFF");
            }
            for (User staffUser : branchStaffs) {
                notificationRepository.save(Notification.builder()
                        .userId(staffUser.getUserId())
                        .bookingId(updated.getBookingId())
                        .title("Khách hàng đã HỦY đặt phòng ⚠️")
                        .message("Đơn #" + updated.getBookingId() + " tại phòng " + updated.getRoom().getNameRoom() + " đã bị hủy.")
                        .read(false)
                        .build());
            }
        } catch (Exception ignored) {}

        return ResponseEntity.ok(ApiResponse.success("Đã huỷ booking", updated));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<Booking>> updateStatus(
            @PathVariable Integer id, @RequestParam String status) {
        return bookingRepository.findById(id).map(b -> {
            b.setStatus(status);
            Booking updated = bookingRepository.save(b);

            // Thông báo cho Khách hàng
            try {
                notificationRepository.save(Notification.builder()
                        .userId(b.getUser().getUserId())
                        .bookingId(b.getBookingId())
                        .title("Cập nhật trạng thái đơn đặt phòng 🔔")
                        .message("Đơn đặt phòng #" + b.getBookingId() + " tại " + b.getRoom().getHotel().getName() + " đã chuyển sang trạng thái: " + status)
                        .read(false)
                        .build());
            } catch (Exception ignored) {}

            return ResponseEntity.ok(ApiResponse.success("Cập nhật trạng thái", updated));
        }).orElse(ResponseEntity.notFound().build());
    }

    // ── Hàm phụ ─────────────────────────────────────────────────────────────
    private Voucher findValidVoucher(String code, BigDecimal orderAmount) {
        Voucher voucher = voucherRepository.findByCode(code.trim().toUpperCase())
                .orElseThrow(() -> new RuntimeException("Mã voucher không tồn tại"));

        if (voucher.getExpiryDate().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("Mã voucher đã hết hạn");
        }
        if (orderAmount.compareTo(voucher.getMinOrderAmount()) < 0) {
            throw new RuntimeException("Đơn tối thiểu để dùng mã này là "
                    + voucher.getMinOrderAmount().setScale(0, RoundingMode.DOWN) + "đ");
        }
        return voucher;
    }

    private BigDecimal calculateDiscount(Voucher voucher, BigDecimal price) {
        BigDecimal discount = BigDecimal.ZERO;
        if (voucher.getDiscountAmount() != null) {
            discount = voucher.getDiscountAmount();
        } else if (voucher.getDiscountPercent() != null) {
            discount = price.multiply(voucher.getDiscountPercent())
                    .divide(BigDecimal.valueOf(100), 0, RoundingMode.DOWN);
        }
        if (discount.compareTo(price) > 0) {
            discount = price;
        }
        return discount;
    }
}
