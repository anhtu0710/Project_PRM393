package genZ.PRM391GenZ.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "notification")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "NotificationId")
    private Integer notificationId;

    @Column(name = "UserId", nullable = false)
    private String userId; // người nhận thông báo

    @Column(name = "BookingId")
    private Integer bookingId; // booking liên quan, có thể để trống

    @Column(name = "Title", nullable = false)
    private String title;

    @Column(name = "Message", nullable = false)
    private String message;

    @Column(name = "IsRead", nullable = false)
    private boolean read; // false = chưa đọc

    // Database tự điền giờ tạo, Java không cần gán
    @Column(name = "CreatedAt", insertable = false, updatable = false)
    private LocalDateTime createdAt;
}
