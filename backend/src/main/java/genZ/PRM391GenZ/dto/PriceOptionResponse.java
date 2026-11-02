package genZ.PRM391GenZ.dto;

import java.math.BigDecimal;

public record PriceOptionResponse(
        String typeBookingId,
        String typeName,
        String bookingCode,
        Integer durationHours,
        BigDecimal price
) {}
