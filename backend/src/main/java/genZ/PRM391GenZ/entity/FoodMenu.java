package genZ.PRM391GenZ.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "FoodMenu")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class FoodMenu {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "FoodId")
    private Integer foodId;

    @Column(name = "Name", nullable = false)
    private String name;

    @Column(name = "Category", nullable = false, length = 100)
    private String category;

    @Column(name = "Price", nullable = false, precision = 18, scale = 2)
    private BigDecimal price;

    @Column(name = "ImageUrl", columnDefinition = "TEXT")
    private String imageUrl;

    @Column(name = "Description", columnDefinition = "TEXT")
    private String description;

    @Builder.Default
    @Column(name = "IsAvailable", nullable = false)
    private Boolean isAvailable = true;
}
