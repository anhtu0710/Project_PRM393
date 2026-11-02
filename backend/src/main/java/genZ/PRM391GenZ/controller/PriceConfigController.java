package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.PriceConfig;
import genZ.PRM391GenZ.repository.PriceConfigRepository;
import genZ.PRM391GenZ.repository.TypeBookingRepository;
import genZ.PRM391GenZ.repository.TypeRoomRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/price-configs")
@RequiredArgsConstructor
public class PriceConfigController {

    private final PriceConfigRepository priceConfigRepository;
    private final TypeRoomRepository typeRoomRepository;
    private final TypeBookingRepository typeBookingRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<PriceConfig>>> getAllPriceConfigs() {
        return ResponseEntity.ok(
                ApiResponse.success("Bảng giá", priceConfigRepository.findAll())
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<PriceConfig>> getPriceConfigById(@PathVariable Integer id) {
        return priceConfigRepository.findById(id)
                .map(price -> ResponseEntity.ok(ApiResponse.success("Thông tin giá", price)))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<PriceConfig>> createPriceConfig(@RequestBody PriceConfig priceConfig) {
        if (priceConfig.getTypeRoom() != null && priceConfig.getTypeRoom().getTypeRoomId() != null) {
            priceConfig.setTypeRoom(typeRoomRepository.findById(priceConfig.getTypeRoom().getTypeRoomId()).orElse(null));
        }
        if (priceConfig.getTypeBooking() != null && priceConfig.getTypeBooking().getTypeBookingId() != null) {
            priceConfig.setTypeBooking(typeBookingRepository.findById(priceConfig.getTypeBooking().getTypeBookingId()).orElse(null));
        }
        PriceConfig saved = priceConfigRepository.save(priceConfig);
        return ResponseEntity.ok(ApiResponse.success("Tạo cấu hình giá thành công", saved));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<PriceConfig>> updatePriceConfig(
            @PathVariable Integer id, @RequestBody PriceConfig priceConfig) {
        PriceConfig existing = priceConfigRepository.findById(id).orElse(null);
        if (existing == null) {
            return ResponseEntity.notFound().build();
        }
        if (priceConfig.getPrice() != null) {
            existing.setPrice(priceConfig.getPrice());
        }
        if (priceConfig.getTypeRoom() != null && priceConfig.getTypeRoom().getTypeRoomId() != null) {
            typeRoomRepository.findById(priceConfig.getTypeRoom().getTypeRoomId())
                    .ifPresent(existing::setTypeRoom);
        }
        if (priceConfig.getTypeBooking() != null && priceConfig.getTypeBooking().getTypeBookingId() != null) {
            typeBookingRepository.findById(priceConfig.getTypeBooking().getTypeBookingId())
                    .ifPresent(existing::setTypeBooking);
        }
        PriceConfig updated = priceConfigRepository.save(existing);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật giá thành công", updated));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<Void>> deletePriceConfig(@PathVariable Integer id) {
        if (!priceConfigRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        priceConfigRepository.deleteById(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa cấu hình giá thành công"));
    }
}
