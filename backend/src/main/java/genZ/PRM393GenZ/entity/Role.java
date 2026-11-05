package genZ.PRM393GenZ.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "role")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Role {

    @Id
    @Column(name = "RoleId", length = 50)
    private String roleId;

    @Column(name = "RoleName", nullable = false)
    private String roleName;
}
