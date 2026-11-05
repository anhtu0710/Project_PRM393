package genZ.PRM393GenZ.service;

import genZ.PRM393GenZ.dto.CreateReviewRequest;
import genZ.PRM393GenZ.dto.ReviewEligibleBookingResponse;
import genZ.PRM393GenZ.dto.ReviewResponse;
import genZ.PRM393GenZ.entity.Booking;
import genZ.PRM393GenZ.entity.Review;
import genZ.PRM393GenZ.entity.User;
import genZ.PRM393GenZ.repository.BookingRepository;
import genZ.PRM393GenZ.repository.ReviewRepository;
import genZ.PRM393GenZ.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ReviewService {
    private static final String COMPLETED = "COMPLETED";

    private final BookingRepository bookingRepository;
    private final ReviewRepository reviewRepository;
    private final UserRepository userRepository;

    @Transactional
    public ReviewResponse create(CreateReviewRequest request, String email) {
        User currentUser = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));
        Booking booking = bookingRepository.findById(request.getBookingId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy booking"));

        if (!booking.getUser().getUserId().equals(currentUser.getUserId())) {
            throw new RuntimeException("Bạn chỉ có thể đánh giá booking của mình");
        }
        if (!COMPLETED.equalsIgnoreCase(booking.getStatus()) || booking.getCheckOut() == null
                || booking.getCheckOut().isAfter(LocalDateTime.now())) {
            throw new RuntimeException("Chỉ có thể đánh giá sau khi đã check-out");
        }
        if (reviewRepository.existsByBooking_BookingId(booking.getBookingId())) {
            throw new RuntimeException("Booking này đã được đánh giá");
        }

        Review review = reviewRepository.save(Review.builder()
                .booking(booking)
                .room(booking.getRoom())
                .user(currentUser)
                .rating(request.getRating())
                .comment(normalizeComment(request.getComment()))
                .build());
        return toResponse(review);
    }

    @Transactional(readOnly = true)
    public List<ReviewEligibleBookingResponse> getEligibleBookings(String email) {
        User currentUser = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));
        return bookingRepository.findByUser_UserIdAndStatusOrderByCheckOutDesc(currentUser.getUserId(), COMPLETED)
                .stream()
                .filter(booking -> booking.getCheckOut() != null && !booking.getCheckOut().isAfter(LocalDateTime.now()))
                .filter(booking -> !reviewRepository.existsByBooking_BookingId(booking.getBookingId()))
                .map(booking -> new ReviewEligibleBookingResponse(booking.getBookingId(),
                        booking.getRoom().getRoomId(), booking.getRoom().getNameRoom(),
                        booking.getRoom().getHotel() == null ? "" : booking.getRoom().getHotel().getName(),
                        booking.getCheckOut()))
                .toList();
    }

    private ReviewResponse toResponse(Review review) {
        return new ReviewResponse(review.getReviewId(), review.getBooking().getBookingId(), review.getRating(),
                review.getComment(), review.getUser().getFullName(), review.getCreatedAt());
    }

    private String normalizeComment(String comment) {
        return comment == null || comment.isBlank() ? null : comment.trim();
    }
}
