package genZ.PRM391GenZ.dto;

import java.time.LocalDateTime;

public record ReviewResponse(
        Integer reviewId,
        Integer bookingId,
        Integer rating,
        String comment,
        String reviewerName,
        LocalDateTime createdAt
) {}
