package genZ.PRM391GenZ.service;

import genZ.PRM391GenZ.dto.PriceOptionResponse;
import genZ.PRM391GenZ.dto.ReviewResponse;
import genZ.PRM391GenZ.dto.RoomResponse;
import genZ.PRM391GenZ.entity.*;
import genZ.PRM391GenZ.repository.PriceConfigRepository;
import genZ.PRM391GenZ.repository.ReviewRepository;
import genZ.PRM391GenZ.repository.RoomRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RoomCatalogService {
    private final RoomRepository roomRepository;
    private final ReviewRepository reviewRepository;
    private final PriceConfigRepository priceConfigRepository;

    @Transactional(readOnly = true)
    public List<RoomResponse> search(String keyword, String hotelId, String typeRoomId,
                                     BigDecimal minPrice, BigDecimal maxPrice,
                                     LocalDateTime checkIn, LocalDateTime checkOut) {
        validateSearchDates(checkIn, checkOut);
        return roomRepository.search(
                        blankToNull(keyword), blankToNull(hotelId), blankToNull(typeRoomId),
                        minPrice, maxPrice, checkIn, checkOut,
                        List.of("PENDING", "CONFIRMED", "CHECKED_IN", "Chưa thanh toán", "Đã xác nhận"))
                .stream()
                .map(room -> toResponse(room, false))
                .toList();
    }

    @Transactional(readOnly = true)
    public RoomResponse getDetail(String roomId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phòng"));
        return toResponse(room, true);
    }

    @Transactional(readOnly = true)
    public List<RoomResponse> getAvailableRooms() {
        return roomRepository.findByStatus("Trống").stream()
                .map(room -> toResponse(room, false))
                .toList();
    }

    public RoomResponse toResponse(Room room, boolean includeDetails) {
        List<Review> reviews = reviewRepository.findByRoom_RoomIdOrderByCreatedAtDesc(room.getRoomId());
        BigDecimal average = reviews.isEmpty() ? BigDecimal.ZERO : BigDecimal.valueOf(
                        reviews.stream().mapToInt(Review::getRating).average().orElse(0))
                .setScale(1, RoundingMode.HALF_UP);

        RoomResponse.TypeRoomData typeRoom = room.getTypeRoom() == null ? null :
                new RoomResponse.TypeRoomData(room.getTypeRoom().getTypeRoomId(),
                        room.getTypeRoom().getTypeRoom(), room.getTypeRoom().getPricePerHour());
        RoomResponse.HotelData hotel = room.getHotel() == null ? null :
                new RoomResponse.HotelData(room.getHotel().getHotelId(), room.getHotel().getName(),
                        room.getHotel().getAddress(), room.getHotel().getPhone(), room.getHotel().getImageUrl());

        List<PriceOptionResponse> prices = includeDetails && room.getTypeRoom() != null
                ? priceConfigRepository.findByTypeRoom_TypeRoomIdOrderByTypeBooking_DurationHoursAsc(
                        room.getTypeRoom().getTypeRoomId()).stream().map(this::toPriceOption).toList()
                : List.of();
        List<ReviewResponse> reviewResponses = includeDetails
                ? reviews.stream().map(this::toReviewResponse).toList()
                : List.of();

        return new RoomResponse(room.getRoomId(), room.getNameRoom(), typeRoom, room.getStatus(), hotel,
                room.getImageUrl(), average, reviews.size(), prices, reviewResponses);
    }

    private PriceOptionResponse toPriceOption(PriceConfig price) {
        TypeBooking booking = price.getTypeBooking();
        return new PriceOptionResponse(booking.getTypeBookingId(), booking.getTypeName(),
                booking.getBookingCode(), booking.getDurationHours(), price.getPrice());
    }

    private ReviewResponse toReviewResponse(Review review) {
        return new ReviewResponse(review.getReviewId(), review.getBooking().getBookingId(), review.getRating(),
                review.getComment(), review.getUser().getFullName(), review.getCreatedAt());
    }

    private void validateSearchDates(LocalDateTime checkIn, LocalDateTime checkOut) {
        if ((checkIn == null) != (checkOut == null)) {
            throw new RuntimeException("Vui lòng chọn cả giờ nhận và giờ trả phòng");
        }
        if (checkIn != null && !checkOut.isAfter(checkIn)) {
            throw new RuntimeException("Giờ trả phòng phải sau giờ nhận phòng");
        }
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
