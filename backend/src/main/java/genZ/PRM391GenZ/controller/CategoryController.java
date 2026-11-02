package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.TypeBooking;
import genZ.PRM391GenZ.entity.TypeRoom;
import genZ.PRM391GenZ.repository.TypeBookingRepository;
import genZ.PRM391GenZ.repository.TypeRoomRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
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
}
