package genZ.PRM393GenZ.controller;

import genZ.PRM393GenZ.dto.ApiResponse;
import genZ.PRM393GenZ.entity.FoodMenu;
import genZ.PRM393GenZ.repository.FoodMenuRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/food-menu")
@RequiredArgsConstructor
public class FoodMenuController {

    private final FoodMenuRepository foodMenuRepository;

    @GetMapping
    @Transactional(readOnly = true)
    public ResponseEntity<ApiResponse<List<FoodMenu>>> getAllFoodMenu(
            @RequestParam(required = false) String category) {
        List<FoodMenu> items;
        if (category != null && !category.isBlank()) {
            items = foodMenuRepository.findByCategoryAndIsAvailableTrue(category.trim());
            if (items.isEmpty()) {
                items = foodMenuRepository.findAll();
            }
        } else {
            items = foodMenuRepository.findByIsAvailableTrue();
            if (items.isEmpty()) {
                items = foodMenuRepository.findAll();
            }
        }
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách thực đơn F&B thành công", items));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<FoodMenu>> createFoodMenu(@RequestBody FoodMenu foodMenu) {
        if (foodMenu.getIsAvailable() == null) {
            foodMenu.setIsAvailable(true);
        }
        FoodMenu saved = foodMenuRepository.save(foodMenu);
        return ResponseEntity.ok(ApiResponse.success("Thêm món ăn/đồ uống thành công", saved));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<FoodMenu>> updateFoodMenu(
            @PathVariable Integer id, @RequestBody FoodMenu foodMenu) {
        if (!foodMenuRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        foodMenu.setFoodId(id);
        if (foodMenu.getIsAvailable() == null) {
            foodMenu.setIsAvailable(true);
        }
        FoodMenu updated = foodMenuRepository.save(foodMenu);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật món ăn thành công", updated));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<Void>> deleteFoodMenu(@PathVariable Integer id) {
        if (!foodMenuRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        foodMenuRepository.deleteById(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa món ăn thành công"));
    }
}
