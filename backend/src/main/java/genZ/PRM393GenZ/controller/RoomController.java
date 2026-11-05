package genZ.PRM393GenZ.controller;

import genZ.PRM393GenZ.constant.RoomStatus;
import genZ.PRM393GenZ.dto.ApiResponse;
import genZ.PRM393GenZ.entity.Room;
import genZ.PRM393GenZ.repository.RoomRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
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
            @RequestParam(required = false) String minPrice,
            @RequestParam(required = false) String maxPrice,
            @RequestParam(required = false) String checkIn,
            @RequestParam(required = false) String checkOut) {

        List<Room> allRooms = roomRepository.findAll();
        var stream = allRooms.stream();

        // 1. Lọc theo hotelId
        if (isNotBlank(hotelId)) {
            final String hId = hotelId.trim().toLowerCase();
            stream = stream.filter(r -> r.getHotel() != null && r.getHotel().getHotelId() != null && r.getHotel().getHotelId().trim().toLowerCase().equals(hId));
        }

        // 2. Lọc theo typeRoomId
        if (isNotBlank(typeRoomId)) {
            final String trId = typeRoomId.trim().toLowerCase();
            stream = stream.filter(r -> r.getTypeRoom() != null && r.getTypeRoom().getTypeRoomId() != null && r.getTypeRoom().getTypeRoomId().trim().toLowerCase().equals(trId));
        }

        // 3. Lọc theo từ khóa (keyword)
        if (isNotBlank(keyword)) {
            final String kw = keyword.trim().toLowerCase();
            stream = stream.filter(r ->
                r.getNameRoom().toLowerCase().contains(kw) ||
                (r.getTypeRoom() != null && r.getTypeRoom().getTypeRoom() != null && r.getTypeRoom().getTypeRoom().toLowerCase().contains(kw)) ||
                (r.getHotel() != null && r.getHotel().getName() != null && r.getHotel().getName().toLowerCase().contains(kw)) ||
                (r.getHotel() != null && r.getHotel().getAddress() != null && r.getHotel().getAddress().toLowerCase().contains(kw))
            );
        }

        // 4. Lọc theo giá tối thiểu
        if (isNotBlank(minPrice)) {
            try {
                BigDecimal minP = new BigDecimal(minPrice.trim());
                stream = stream.filter(r -> r.getTypeRoom() != null && r.getTypeRoom().getPricePerHour() != null && r.getTypeRoom().getPricePerHour().compareTo(minP) >= 0);
            } catch (Exception ignored) {}
        }

        // 5. Lọc theo giá tối đa
        if (isNotBlank(maxPrice)) {
            try {
                BigDecimal maxP = new BigDecimal(maxPrice.trim());
                stream = stream.filter(r -> r.getTypeRoom() != null && r.getTypeRoom().getPricePerHour() != null && r.getTypeRoom().getPricePerHour().compareTo(maxP) <= 0);
            } catch (Exception ignored) {}
        }

        List<Room> filtered = stream.toList();
        return ResponseEntity.ok(ApiResponse.success("Danh sách phòng phù hợp", filtered));
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
}
