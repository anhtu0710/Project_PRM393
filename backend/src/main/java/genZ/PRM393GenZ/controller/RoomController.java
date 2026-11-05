package genZ.PRM393GenZ.controller;

import genZ.PRM393GenZ.constant.RoomStatus;
import genZ.PRM393GenZ.dto.ApiResponse;
import genZ.PRM393GenZ.entity.Room;
import genZ.PRM393GenZ.repository.RoomRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/rooms")
@RequiredArgsConstructor
public class RoomController {

    private final RoomRepository roomRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Room>>> getAllRooms(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String hotelId,
            @RequestParam(required = false) String typeRoomId,
            @RequestParam(required = false) BigDecimal minPrice,
            @RequestParam(required = false) BigDecimal maxPrice,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime checkIn,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime checkOut) {

        // Shortcut cho filter theo hotelId đơn thuần
        if (isNotBlank(hotelId) && isBlank(keyword) && isBlank(typeRoomId)
                && minPrice == null && maxPrice == null && checkIn == null && checkOut == null) {
            return ResponseEntity.ok(
                    ApiResponse.success("Danh sách phòng theo chi nhánh", roomRepository.findByHotel_HotelId(hotelId.trim()))
            );
        }

        if (isBlank(keyword) && isBlank(hotelId) && isBlank(typeRoomId)
                && minPrice == null && maxPrice == null && checkIn == null && checkOut == null) {
            return ResponseEntity.ok(
                    ApiResponse.success("Danh sách phòng", roomRepository.findAll())
            );
        }

        LocalDateTime effectiveCheckIn = checkIn != null ? checkIn : LocalDateTime.of(2000, 1, 1, 0, 0);
        LocalDateTime effectiveCheckOut = checkOut != null ? checkOut : LocalDateTime.of(2099, 12, 31, 23, 59);

        List<Room> rooms = roomRepository.search(
                blankToNull(keyword),
                blankToNull(hotelId),
                blankToNull(typeRoomId),
                minPrice, maxPrice, effectiveCheckIn, effectiveCheckOut,
                List.of("PENDING", "CONFIRMED", "CHECKED_IN", "Chưa thanh toán", "Đã xác nhận")
        );

        return ResponseEntity.ok(
                ApiResponse.success("Danh sách phòng phù hợp", rooms)
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
        roomRepository.deleteById(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa phòng thành công"));
    }

    private boolean isBlank(String str) {
        return str == null || str.isBlank();
    }

    private boolean isNotBlank(String str) {
        return str != null && !str.isBlank();
    }

    private String blankToNull(String str) {
        return isBlank(str) ? null : str.trim();
    }
}
