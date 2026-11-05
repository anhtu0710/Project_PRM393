package genZ.PRM393GenZ.controller;

import genZ.PRM393GenZ.dto.ApiResponse;
import genZ.PRM393GenZ.entity.Voucher;
import genZ.PRM393GenZ.repository.VoucherRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/vouchers")
@RequiredArgsConstructor
public class VoucherController {

    private final VoucherRepository voucherRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Voucher>>> getAllVouchers() {
        return ResponseEntity.ok(
                ApiResponse.success("Danh sách voucher", voucherRepository.findAll())
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Voucher>> getVoucherById(@PathVariable Integer id) {
        return voucherRepository.findById(id)
                .map(voucher -> ResponseEntity.ok(ApiResponse.success("Thông tin voucher", voucher)))
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/code/{code}")
    public ResponseEntity<ApiResponse<Voucher>> getVoucherByCode(@PathVariable String code) {
        return voucherRepository.findByCode(code)
                .map(voucher -> ResponseEntity.ok(ApiResponse.success("Thông tin voucher", voucher)))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<Voucher>> createVoucher(@RequestBody Voucher voucher) {
        if (voucher.getCode() == null || voucher.getCode().isBlank()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Mã voucher không được để trống"));
        }
        String cleanCode = voucher.getCode().trim().toUpperCase();
        if (voucherRepository.findByCode(cleanCode).isPresent()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Mã voucher '" + cleanCode + "' đã tồn tại"));
        }
        voucher.setCode(cleanCode);
        Voucher saved = voucherRepository.save(voucher);
        return ResponseEntity.ok(ApiResponse.success("Tạo voucher thành công", saved));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<Voucher>> updateVoucher(
            @PathVariable Integer id, @RequestBody Voucher voucher) {
        Voucher existing = voucherRepository.findById(id).orElse(null);
        if (existing == null) {
            return ResponseEntity.notFound().build();
        }

        if (voucher.getCode() != null && !voucher.getCode().isBlank()) {
            String cleanCode = voucher.getCode().trim().toUpperCase();
            // Nếu đổi mã sang mã khác đã tồn tại -> báo lỗi
            if (!cleanCode.equalsIgnoreCase(existing.getCode()) && voucherRepository.findByCode(cleanCode).isPresent()) {
                return ResponseEntity.badRequest().body(ApiResponse.error("Mã voucher '" + cleanCode + "' đã tồn tại"));
            }
            existing.setCode(cleanCode);
        }

        if (voucher.getDescription() != null) existing.setDescription(voucher.getDescription());
        if (voucher.getDiscountPercent() != null) existing.setDiscountPercent(voucher.getDiscountPercent());
        if (voucher.getDiscountAmount() != null) existing.setDiscountAmount(voucher.getDiscountAmount());
        if (voucher.getMinOrderAmount() != null) existing.setMinOrderAmount(voucher.getMinOrderAmount());
        if (voucher.getExpiryDate() != null) existing.setExpiryDate(voucher.getExpiryDate());

        Voucher updated = voucherRepository.save(existing);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật voucher thành công", updated));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<Void>> deleteVoucher(@PathVariable Integer id) {
        if (!voucherRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        voucherRepository.deleteById(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa voucher thành công"));
    }
}
