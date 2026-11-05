package genZ.PRM393GenZ.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "booking")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Booking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "BookingId")
    private Integer bookingId;

    // EAGER: lấy booking thì lấy luôn phòng, khách, combo (trả JSON không bị lỗi)
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "RoomId", nullable = false)
    private Room room;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "UserId", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "TypeBookingId", nullable = false)
    private TypeBooking typeBooking;

    @Column(name = "checkIn", nullable = false)
    private LocalDateTime checkIn;

    @Column(name = "checkOut")
    private LocalDateTime checkOut;

    @Column(name = "totalPrice", precision = 18, scale = 2)
    private BigDecimal totalPrice;

    @Column(name = "Status")
    private String status;

    @Column(name = "voucherCode", length = 50)
    private String voucherCode;

    @Column(name = "discountAmount", precision = 18, scale = 2)
    private BigDecimal discountAmount;

    @Column(name = "note", columnDefinition = "TEXT")
    private String note;
}
