package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.constant.BookingStatus;
import genZ.PRM391GenZ.constant.RoomStatus;
import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.Booking;
import genZ.PRM391GenZ.entity.Room;
import genZ.PRM391GenZ.repository.BookingRepository;
import genZ.PRM391GenZ.repository.RoomRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/rooms")
@RequiredArgsConstructor
public class RoomController {

    private final RoomRepository roomRepository;
    private final BookingRepository bookingRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Room>>> getAllRooms() {
        return ResponseEntity.ok(
                ApiResponse.success("Danh sách phòng", roomRepository.findAll())
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Room>> getRoomById(@PathVariable String id) {
        return roomRepository.findById(id)
                .map(room -> ResponseEntity.ok(ApiResponse.success("Thông tin phòng", room)))
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/available")
    public ResponseEntity<ApiResponse<List<Room>>> getAvailableRooms() {
        List<Room> rooms = roomRepository.findByStatus(RoomStatus.AVAILABLE);
        return ResponseEntity.ok(ApiResponse.success("Phòng trống", rooms));
    }

    @GetMapping("/hotel/{hotelId}")
    public ResponseEntity<ApiResponse<List<Room>>> getRoomsByHotel(@PathVariable String hotelId) {
        List<Room> rooms = roomRepository.findByHotel_HotelId(hotelId);
        return ResponseEntity.ok(ApiResponse.success("Phòng theo khách sạn", rooms));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<Room>> createRoom(@RequestBody Room room) {
        Room saved = roomRepository.save(room);
        return ResponseEntity.ok(ApiResponse.success("Tạo phòng thành công", saved));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<Room>> updateRoom(
            @PathVariable String id, @RequestBody Room room) {
        if (!roomRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        room.setRoomId(id);
        Room updated = roomRepository.save(room);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật phòng thành công", updated));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<Void>> deleteRoom(@PathVariable String id) {
        if (!roomRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }

        // TV5: Chặn xóa phòng còn booking đang hoạt động (PENDING, CONFIRMED, CHECKED_IN)
        List<Booking> bookings = bookingRepository.findByRoom_RoomId(id);
        boolean hasActiveBooking = bookings.stream().anyMatch(b ->
                BookingStatus.PENDING.equalsIgnoreCase(b.getStatus()) ||
                BookingStatus.CONFIRMED.equalsIgnoreCase(b.getStatus()) ||
                BookingStatus.CHECKED_IN.equalsIgnoreCase(b.getStatus())
        );

        if (hasActiveBooking) {
            return ResponseEntity.badRequest().body(
                    ApiResponse.error("Không thể xóa phòng đang có booking hoạt động")
            );
        }

        roomRepository.deleteById(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa phòng thành công"));
    }
}
