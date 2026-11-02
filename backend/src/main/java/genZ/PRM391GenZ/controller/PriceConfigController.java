package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.PriceConfig;
import genZ.PRM391GenZ.repository.PriceConfigRepository;
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
        PriceConfig saved = priceConfigRepository.save(priceConfig);
        return ResponseEntity.ok(ApiResponse.success("Tạo cấu hình giá thành công", saved));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<PriceConfig>> updatePriceConfig(
            @PathVariable Integer id, @RequestBody PriceConfig priceConfig) {
        if (!priceConfigRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        priceConfig.setPriceConfigId(id);
        PriceConfig updated = priceConfigRepository.save(priceConfig);
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
