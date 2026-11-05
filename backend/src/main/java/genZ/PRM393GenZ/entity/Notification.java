package genZ.PRM393GenZ.entity;

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

    @Column(name = "Type", length = 50)
    private String type; // BOOKING_NEW, BOOKING_CONFIRMED, ROOM_CLEANING...

    @Column(name = "RecipientRole", length = 20)
    private String recipientRole; // CUSTOMER, STAFF, ADMIN

    @Column(name = "Title", nullable = false)
    private String title;

    @Column(name = "Message", nullable = false)
    private String message;

    @Column(name = "IsRead", nullable = false)
    private boolean read; // false = chưa đọc

    @Column(name = "CreatedAt", insertable = false, updatable = false)
    private LocalDateTime createdAt;
}
