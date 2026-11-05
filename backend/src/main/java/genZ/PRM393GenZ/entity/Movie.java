package genZ.PRM393GenZ.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "movie")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Movie {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MovieId")
    private Integer movieId;

    @Column(name = "Title", nullable = false)
    private String title;

    @Column(name = "Category", nullable = false, length = 100)
    private String category;

    @Column(name = "Rating", nullable = false, precision = 3, scale = 1)
    private BigDecimal rating;

    @Column(name = "Quality", nullable = false, length = 50)
    private String quality;

    @Column(name = "PosterUrl", columnDefinition = "TEXT")
    private String posterUrl;

    @Column(name = "Description", columnDefinition = "TEXT")
    private String description;

    @Builder.Default
    @Column(name = "IsHot", nullable = false)
    private Boolean isHot = true;
}
