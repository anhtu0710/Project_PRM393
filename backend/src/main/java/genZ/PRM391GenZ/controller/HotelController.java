package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.Hotel;
import genZ.PRM391GenZ.entity.Room;
import genZ.PRM391GenZ.repository.HotelRepository;
import genZ.PRM391GenZ.repository.RoomRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/hotels")
@RequiredArgsConstructor
public class HotelController {

    private final HotelRepository hotelRepository;
    private final RoomRepository roomRepository;

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
    public ResponseEntity<ApiResponse<Void>> deleteHotel(@PathVariable String id) {
        if (!hotelRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        List<Room> rooms = roomRepository.findByHotel_HotelId(id);
        if (!rooms.isEmpty()) {
            return ResponseEntity.badRequest().body(
                    ApiResponse.error("Không thể xóa chi nhánh đang có " + rooms.size() + " phòng thuộc cơ sở này")
            );
        }
        hotelRepository.deleteById(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa chi nhánh thành công"));
    }
}
