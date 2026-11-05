package genZ.PRM393GenZ.dto;

import java.math.BigDecimal;
import java.util.List;

/** Explicit API shape so room discovery never serializes JPA proxy objects. */
public record RoomResponse(
        String roomId,
        String nameRoom,
        TypeRoomData typeRoom,
        String status,
        HotelData hotel,
        String imageUrl,
        String description,
        String amenities,
        BigDecimal averageRating,
        long reviewCount,
        List<PriceOptionResponse> priceOptions,
        List<ReviewResponse> reviews
) {
    public record TypeRoomData(String typeRoomId, String typeRoom, BigDecimal pricePerHour) {}
    public record HotelData(String hotelId, String name, String address, String phone, String imageUrl, String city) {}
}
