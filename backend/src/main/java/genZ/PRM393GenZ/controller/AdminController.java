package genZ.PRM393GenZ.controller;

import genZ.PRM393GenZ.dto.AdminStatsResponse;
import genZ.PRM393GenZ.dto.ApiResponse;
import genZ.PRM393GenZ.entity.Hotel;
import genZ.PRM393GenZ.entity.Role;
import genZ.PRM393GenZ.entity.User;
import genZ.PRM393GenZ.repository.HotelRepository;
import genZ.PRM393GenZ.repository.RoleRepository;
import genZ.PRM393GenZ.repository.UserRepository;
import genZ.PRM393GenZ.service.StatsService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')") // mọi API trong class này chỉ ADMIN gọi được
public class AdminController {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final HotelRepository hotelRepository;
    private final StatsService statsService;

    // ── Quản lý người dùng ──────────────────────────────────────────────────

    // GET /api/admin/users — danh sách tất cả tài khoản
    @GetMapping("/users")
    public ResponseEntity<ApiResponse<List<User>>> getUsers() {
        return ResponseEntity.ok(ApiResponse.success("Danh sách người dùng", userRepository.findAll()));
    }

    // PUT /api/admin/users/{id}/role?roleId=STAFF — đổi role giữa CUSTOMER và STAFF
    @PutMapping("/users/{id}/role")
    public ResponseEntity<ApiResponse<User>> changeRole(
            @PathVariable String id, @RequestParam String roleId) {
        User user = findUser(id);

        if (isAdmin(user)) {
            throw new RuntimeException("Không thể đổi role của tài khoản Admin");
        }
        if (!"CUSTOMER".equals(roleId) && !"STAFF".equals(roleId)) {
            throw new RuntimeException("Chỉ đổi được giữa CUSTOMER và STAFF");
        }

        Role role = roleRepository.findById(roleId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy role " + roleId));
        user.setRole(role);
        User saved = userRepository.save(user);
        return ResponseEntity.ok(ApiResponse.success("Đã đổi role thành " + role.getRoleName(), saved));
    }

    // PUT /api/admin/users/{id}/hotel?hotelId=HN002 — gán chi nhánh cho Staff
    @PutMapping("/users/{id}/hotel")
    public ResponseEntity<ApiResponse<User>> assignHotel(
            @PathVariable String id, @RequestParam(required = false) String hotelId) {
        User user = findUser(id);

        if (hotelId != null && !hotelId.isBlank()) {
            Hotel hotel = hotelRepository.findById(hotelId.trim())
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy chi nhánh " + hotelId));
            user.setHotel(hotel);
        } else {
            user.setHotel(null);
        }

        User saved = userRepository.save(user);
        return ResponseEntity.ok(ApiResponse.success("Đã cập nhật chi nhánh phụ trách", saved));
    }

    // PUT /api/admin/users/{id}/lock?locked=true — khoá (true) hoặc mở khoá (false)
    @PutMapping("/users/{id}/lock")
    public ResponseEntity<ApiResponse<User>> setLocked(
            @PathVariable String id, @RequestParam boolean locked) {
        User user = findUser(id);

        if (isAdmin(user)) {
            throw new RuntimeException("Không thể khoá tài khoản Admin");
        }

        user.setLocked(locked);
        User saved = userRepository.save(user);
        String message = locked ? "Đã khoá tài khoản" : "Đã mở khoá tài khoản";
        return ResponseEntity.ok(ApiResponse.success(message, saved));
    }

    // ── Thống kê cho dashboard ──────────────────────────────────────────────

    // GET /api/admin/stats?period=day|week|month
    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<AdminStatsResponse>> getStats(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(defaultValue = "day") String period) {
        return ResponseEntity.ok(ApiResponse.success("Thống kê", statsService.getStats(startDate, endDate, period)));
    }

    // ── Hàm phụ ─────────────────────────────────────────────────────────────

    private User findUser(String id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));
    }

    private boolean isAdmin(User user) {
        return user.getRole() != null && "ADMIN".equals(user.getRole().getRoleId());
    }
}
