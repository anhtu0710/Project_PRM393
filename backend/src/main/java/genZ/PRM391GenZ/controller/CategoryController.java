package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.TypeBooking;
import genZ.PRM391GenZ.entity.TypeRoom;
import genZ.PRM391GenZ.repository.TypeBookingRepository;
import genZ.PRM391GenZ.repository.TypeRoomRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class CategoryController {

    private final TypeRoomRepository typeRoomRepository;
    private final TypeBookingRepository typeBookingRepository;

    @GetMapping("/type-rooms")
    public ResponseEntity<ApiResponse<List<TypeRoom>>> getAllTypeRooms() {
        return ResponseEntity.ok(
                ApiResponse.success("Danh sách loại phòng", typeRoomRepository.findAll())
        );
    }

    @GetMapping("/type-bookings")
    public ResponseEntity<ApiResponse<List<TypeBooking>>> getAllTypeBookings() {
        return ResponseEntity.ok(
                ApiResponse.success("Danh sách loại đặt phòng", typeBookingRepository.findAll())
        );
    }

    @PostMapping("/type-bookings")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<TypeBooking>> createTypeBooking(@RequestBody TypeBooking typeBooking) {
        if (typeBooking.getTypeBookingId() == null || typeBooking.getTypeBookingId().isBlank()) {
            typeBooking.setTypeBookingId("TB_" + (System.currentTimeMillis() % 100000));
        }
        TypeBooking saved = typeBookingRepository.save(typeBooking);
        return ResponseEntity.ok(ApiResponse.success("Tạo gói combo mới thành công", saved));
    }

    @PostMapping("/type-rooms")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<TypeRoom>> createTypeRoom(@RequestBody TypeRoom typeRoom) {
        if (typeRoom.getTypeRoomId() == null || typeRoom.getTypeRoomId().isBlank()) {
            typeRoom.setTypeRoomId("TR_" + (System.currentTimeMillis() % 100000));
        }
        TypeRoom saved = typeRoomRepository.save(typeRoom);
        return ResponseEntity.ok(ApiResponse.success("Tạo loại phòng mới thành công", saved));
    }
}
