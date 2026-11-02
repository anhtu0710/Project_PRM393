package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.Voucher;
import genZ.PRM391GenZ.repository.VoucherRepository;
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
        Voucher saved = voucherRepository.save(voucher);
        return ResponseEntity.ok(ApiResponse.success("Tạo voucher thành công", saved));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<Voucher>> updateVoucher(
            @PathVariable Integer id, @RequestBody Voucher voucher) {
        if (!voucherRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        voucher.setVoucherId(id);
        Voucher updated = voucherRepository.save(voucher);
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
