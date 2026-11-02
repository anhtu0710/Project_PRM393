package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.constant.BookingStatus;
import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.Booking;
import genZ.PRM391GenZ.entity.Hotel;
import genZ.PRM391GenZ.entity.Room;
import genZ.PRM391GenZ.repository.BookingRepository;
import genZ.PRM391GenZ.repository.HotelRepository;
import genZ.PRM391GenZ.repository.NotificationRepository;
import genZ.PRM391GenZ.repository.ReviewRepository;
import genZ.PRM391GenZ.repository.RoomRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/hotels")
@RequiredArgsConstructor
public class HotelController {

    private final HotelRepository hotelRepository;
    private final RoomRepository roomRepository;
    private final BookingRepository bookingRepository;
    private final ReviewRepository reviewRepository;
    private final NotificationRepository notificationRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Hotel>>> getAllHotels() {
        return ResponseEntity.ok(
                ApiResponse.success("Danh sách chi nhánh", hotelRepository.findAll())
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Hotel>> getHotelById(@PathVariable String id) {
        return hotelRepository.findById(id)
                .map(hotel -> ResponseEntity.ok(ApiResponse.success("Thông tin chi nhánh", hotel)))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<Hotel>> createHotel(@RequestBody Hotel hotel) {
        Hotel saved = hotelRepository.save(hotel);
        return ResponseEntity.ok(ApiResponse.success("Thêm chi nhánh thành công", saved));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<Hotel>> updateHotel(
            @PathVariable String id, @RequestBody Hotel hotel) {
        if (!hotelRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        hotel.setHotelId(id);
        Hotel updated = hotelRepository.save(hotel);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật chi nhánh thành công", updated));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    @Transactional
    public ResponseEntity<ApiResponse<Void>> deleteHotel(@PathVariable String id) {
        if (!hotelRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }

        List<Room> rooms = roomRepository.findByHotel_HotelId(id);

        // 1. Kiểm tra nếu có bất kỳ phòng nào đang có booking hoạt động (PENDING, CONFIRMED, CHECKED_IN) -> Chặn xóa
        for (Room room : rooms) {
            List<Booking> activeBookings = bookingRepository.findByRoom_RoomId(room.getRoomId()).stream()
                    .filter(b -> BookingStatus.PENDING.equalsIgnoreCase(b.getStatus())
                            || BookingStatus.CONFIRMED.equalsIgnoreCase(b.getStatus())
                            || BookingStatus.CHECKED_IN.equalsIgnoreCase(b.getStatus()))
                    .toList();
            if (!activeBookings.isEmpty()) {
                return ResponseEntity.badRequest().body(
                        ApiResponse.error("Không thể xóa chi nhánh vì phòng " + room.getNameRoom()
                                + " (" + room.getRoomId() + ") đang có " + activeBookings.size() + " booking đang hoạt động!")
                );
            }
        }

        // 2. Logic xóa chi nhánh: Xóa toàn bộ phòng thuộc chi nhánh (cùng dữ liệu review/booking hoàn tất cũ)
        for (Room room : rooms) {
            List<Booking> roomBookings = bookingRepository.findByRoom_RoomId(room.getRoomId());
            for (Booking booking : roomBookings) {
                // Xóa review & notification liên quan đến booking này
                reviewRepository.findByRoom_RoomId(room.getRoomId()).forEach(reviewRepository::delete);
                if (booking.getUser() != null) {
                    notificationRepository.findByUserId(booking.getUser().getUserId()).stream()
                            .filter(n -> n.getBookingId() != null && n.getBookingId().equals(booking.getBookingId()))
                            .forEach(notificationRepository::delete);
                }
                bookingRepository.delete(booking);
            }
            // Xóa nốt các review của phòng
            reviewRepository.findByRoom_RoomId(room.getRoomId()).forEach(reviewRepository::delete);

            // Xóa phòng
            roomRepository.delete(room);
        }

        // 3. Xóa chi nhánh
        hotelRepository.deleteById(id);

        return ResponseEntity.ok(ApiResponse.success("Xóa chi nhánh và toàn bộ phòng thuộc chi nhánh thành công"));
    }
}
