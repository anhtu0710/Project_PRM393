package genZ.PRM393GenZ.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "\"user\"")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @Column(name = "UserId", length = 50)
    private String userId;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(name = "phone", length = 20)
    private String phone;

    @Column(name = "email", length = 255)
    private String email;

    @JsonIgnore // không trả mật khẩu ra JSON
    @Column(name = "password", nullable = false)
    private String password;

    @Column(name = "Image_cccd", columnDefinition = "TEXT")
    private String imageCccd;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "RoleId")
    private Role role;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "HotelId")
    private Hotel hotel; // Chi nhánh phụ trách (nếu là STAFF)

    @Column(name = "IsLocked", nullable = false)
    private boolean locked; // true = tài khoản bị khoá
}
