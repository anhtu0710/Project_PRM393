package genZ.PRM391GenZ.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "Review")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ReviewId")
    private Integer reviewId;

    @Column(name = "BookingId", nullable = false)
    private Integer bookingId; // mỗi booking chỉ đánh giá 1 lần

    @Column(name = "RoomId", nullable = false)
    private String roomId;

    @Column(name = "UserId", nullable = false)
    private String userId;

    @Column(name = "Rating", nullable = false)
    private Integer rating; // 1 đến 5 sao

    @Column(name = "Comment")
    private String comment;

    // Database tự điền giờ tạo, Java không cần gán
    @Column(name = "CreatedAt", insertable = false, updatable = false)
    private LocalDateTime createdAt;
}
