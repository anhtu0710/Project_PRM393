package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.FoodMenu;
import genZ.PRM391GenZ.repository.FoodMenuRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/food-menu")
@RequiredArgsConstructor
public class FoodMenuController {

    private final FoodMenuRepository foodMenuRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<FoodMenu>>> getAllFoodMenu(
            @RequestParam(required = false) String category) {
        List<FoodMenu> items;
        if (category != null && !category.isBlank()) {
            items = foodMenuRepository.findByCategoryAndIsAvailableTrue(category.trim());
        } else {
            items = foodMenuRepository.findByIsAvailableTrue();
        }
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách thực đơn F&B thành công", items));
    }
}
