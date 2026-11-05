package genZ.PRM393GenZ.controller;

import genZ.PRM393GenZ.dto.*;
import genZ.PRM393GenZ.service.ReviewService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/reviews")
@RequiredArgsConstructor
public class ReviewController {
    private final ReviewService reviewService;

    @GetMapping("/eligible")
    public ResponseEntity<ApiResponse<List<ReviewEligibleBookingResponse>>> eligibleBookings(Authentication authentication) {
        return ResponseEntity.ok(ApiResponse.success("Các lượt lưu trú có thể đánh giá",
                reviewService.getEligibleBookings(authentication.getName())));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ReviewResponse>> createReview(
            @Valid @RequestBody CreateReviewRequest request, Authentication authentication) {
        return ResponseEntity.ok(ApiResponse.success("Cảm ơn bạn đã đánh giá", 
                reviewService.create(request, authentication.getName())));
    }
}
