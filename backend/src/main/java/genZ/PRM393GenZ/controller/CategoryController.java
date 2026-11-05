package genZ.PRM393GenZ.controller;

import genZ.PRM393GenZ.dto.ApiResponse;
import genZ.PRM393GenZ.entity.PriceConfig;
import genZ.PRM393GenZ.entity.TypeBooking;
import genZ.PRM393GenZ.entity.TypeRoom;
import genZ.PRM393GenZ.repository.PriceConfigRepository;
import genZ.PRM393GenZ.repository.TypeBookingRepository;
import genZ.PRM393GenZ.repository.TypeRoomRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequiredArgsConstructor
public class CategoryController {

    private final TypeRoomRepository typeRoomRepository;
    private final TypeBookingRepository typeBookingRepository;
    private final PriceConfigRepository priceConfigRepository;

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
    @Transactional
    public ResponseEntity<ApiResponse<TypeBooking>> createTypeBooking(@RequestBody TypeBooking typeBooking) {
        if (typeBooking.getTypeBookingId() == null || typeBooking.getTypeBookingId().isBlank()) {
            typeBooking.setTypeBookingId("TB_" + (System.currentTimeMillis() % 100000));
        }
        TypeBooking saved = typeBookingRepository.save(typeBooking);

        // Tự động sinh PriceConfig cho tất cả các TypeRoom nếu chưa có
        List<TypeRoom> typeRooms = typeRoomRepository.findAll();
        for (TypeRoom tr : typeRooms) {
            boolean exists = priceConfigRepository
                    .findByTypeRoom_TypeRoomIdAndTypeBooking_TypeBookingId(tr.getTypeRoomId(), saved.getTypeBookingId())
                    .isPresent();
            if (!exists) {
                BigDecimal hourly = tr.getPricePerHour() != null ? tr.getPricePerHour() : new BigDecimal("96000");
                int hours = saved.getDurationHours() != null ? saved.getDurationHours() : 2;
                BigDecimal calculatedPrice = hourly.multiply(BigDecimal.valueOf(hours));

                priceConfigRepository.save(PriceConfig.builder()
                        .typeRoom(tr)
                        .typeBooking(saved)
                        .price(calculatedPrice)
                        .build());
            }
        }

        return ResponseEntity.ok(ApiResponse.success("Tạo gói combo mới thành công", saved));
    }

    @PutMapping("/type-bookings/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<TypeBooking>> updateTypeBooking(
            @PathVariable String id, @RequestBody TypeBooking updated) {
        return typeBookingRepository.findById(id)
                .map(existing -> {
                    if (updated.getTypeName() != null && !updated.getTypeName().isBlank()) {
                        existing.setTypeName(updated.getTypeName());
                    }
                    if (updated.getBookingCode() != null && !updated.getBookingCode().isBlank()) {
                        existing.setBookingCode(updated.getBookingCode());
                    }
                    if (updated.getDurationHours() != null) {
                        existing.setDurationHours(updated.getDurationHours());
                    }
                    TypeBooking saved = typeBookingRepository.save(existing);
                    return ResponseEntity.ok(ApiResponse.success("Cập nhật gói combo thành công", saved));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/type-bookings/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    @Transactional
    public ResponseEntity<ApiResponse<Void>> deleteTypeBooking(@PathVariable String id) {
        if (!typeBookingRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        // Delete associated PriceConfig entries first
        List<PriceConfig> configs = priceConfigRepository.findAll();
        for (PriceConfig pc : configs) {
            if (pc.getTypeBooking() != null && id.equalsIgnoreCase(pc.getTypeBooking().getTypeBookingId())) {
                priceConfigRepository.delete(pc);
            }
        }
        typeBookingRepository.deleteById(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa gói combo thành công"));
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
