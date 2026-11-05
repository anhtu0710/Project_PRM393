package genZ.PRM393GenZ.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "voucher")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Voucher {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "VoucherId")
    private Integer voucherId;

    @Column(name = "Code", nullable = false, length = 50)
    private String code;

    @Column(name = "Description")
    private String description;

    // Chỉ điền 1 trong 2: giảm theo % HOẶC giảm theo số tiền
    @Column(name = "DiscountPercent")
    private BigDecimal discountPercent;

    @Column(name = "DiscountAmount")
    private BigDecimal discountAmount;

    // Đơn tối thiểu để dùng mã. Không giới hạn thì để 0 (không được để trống)
    @Column(name = "MinOrderAmount", nullable = false)
    private BigDecimal minOrderAmount;

    @Column(name = "ExpiryDate", nullable = false)
    private LocalDateTime expiryDate;
}
