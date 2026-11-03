package genZ.PRM391GenZ.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "hotel")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Hotel {

    @Id
    @Column(name = "HotelId", length = 50)
    private String hotelId;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "address", columnDefinition = "TEXT")
    private String address;

    @Column(name = "countRoom")
    private Integer countRoom = 0;

    @Column(name = "phone", length = 20)
    private String phone;

    @Column(name = "imageUrl", columnDefinition = "TEXT")
    private String imageUrl;

    @Column(name = "City", length = 100)
    private String city;
}
