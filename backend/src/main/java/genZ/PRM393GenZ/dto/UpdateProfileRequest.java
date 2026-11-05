package genZ.PRM393GenZ.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateProfileRequest {
    private String fullName;
    private String email;
    private String phone;
}
