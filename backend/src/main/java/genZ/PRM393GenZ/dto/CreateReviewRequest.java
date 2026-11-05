package genZ.PRM393GenZ.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateReviewRequest {
    @NotNull(message = "Booking không được để trống")
    private Integer bookingId;

    @NotNull(message = "Vui lòng chọn số sao")
    @Min(value = 1, message = "Đánh giá phải từ 1 đến 5 sao")
    @Max(value = 5, message = "Đánh giá phải từ 1 đến 5 sao")
    private Integer rating;

    @Size(max = 1000, message = "Nhận xét không được quá 1000 ký tự")
    private String comment;
}
