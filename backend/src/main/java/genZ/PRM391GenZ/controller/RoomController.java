package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.dto.RoomResponse;
import genZ.PRM391GenZ.entity.Room;
import genZ.PRM391GenZ.repository.RoomRepository;
import genZ.PRM391GenZ.service.RoomCatalogService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.format.annotation.DateTimeFormat;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/rooms")
@RequiredArgsConstructor
public class RoomController {

    private final RoomRepository roomRepository;
    private final RoomCatalogService roomCatalogService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<RoomResponse>>> getAllRooms(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String hotelId,
            @RequestParam(required = false) String typeRoomId,
            @RequestParam(required = false) BigDecimal minPrice,
            @RequestParam(required = false) BigDecimal maxPrice,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime checkIn,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime checkOut) {
        return ResponseEntity.ok(
                ApiResponse.success("Danh sách phòng", roomCatalogService.search(
                        keyword, hotelId, typeRoomId, minPrice, maxPrice, checkIn, checkOut))
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<RoomResponse>> getRoomById(@PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.success("Thông tin phòng", roomCatalogService.getDetail(id)));
    }

    @GetMapping("/available")
    public ResponseEntity<ApiResponse<List<RoomResponse>>> getAvailableRooms() {
        return ResponseEntity.ok(ApiResponse.success("Phòng trống", roomCatalogService.getAvailableRooms()));
    }

    @GetMapping("/hotel/{hotelId}")
    public ResponseEntity<ApiResponse<List<RoomResponse>>> getRoomsByHotel(@PathVariable String hotelId) {
        return ResponseEntity.ok(ApiResponse.success("Phòng theo khách sạn",
                roomCatalogService.search(null, hotelId, null, null, null, null, null)));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Room>> createRoom(@RequestBody Room room) {
        Room saved = roomRepository.save(room);
        return ResponseEntity.ok(ApiResponse.success("Tạo phòng thành công", saved));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
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
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteRoom(@PathVariable String id) {
        if (!roomRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        roomRepository.deleteById(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa phòng thành công"));
    }
}
