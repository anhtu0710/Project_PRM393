package genZ.PRM391GenZ.dto;

import java.time.LocalDateTime;

public record ReviewEligibleBookingResponse(
        Integer bookingId,
        String roomId,
        String roomName,
        String hotelName,
        LocalDateTime checkOut
) {}
