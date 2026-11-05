package genZ.PRM393GenZ.repository;

import genZ.PRM393GenZ.entity.Movie;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MovieRepository extends JpaRepository<Movie, Integer> {
    List<Movie> findByIsHotTrue();
    List<Movie> findByCategoryAndIsHotTrue(String category);
}
