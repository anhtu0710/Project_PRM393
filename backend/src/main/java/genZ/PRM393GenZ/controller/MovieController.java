package genZ.PRM393GenZ.controller;

import genZ.PRM393GenZ.dto.ApiResponse;
import genZ.PRM393GenZ.entity.Movie;
import genZ.PRM393GenZ.repository.MovieRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/movies")
@RequiredArgsConstructor
public class MovieController {

    private final MovieRepository movieRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Movie>>> getAllMovies(
            @RequestParam(required = false) String category) {
        List<Movie> movies;
        if (category != null && !category.isBlank()) {
            movies = movieRepository.findByCategoryAndIsHotTrue(category.trim());
            if (movies.isEmpty()) {
                movies = movieRepository.findAll();
            }
        } else {
            movies = movieRepository.findByIsHotTrue();
            if (movies.isEmpty()) {
                movies = movieRepository.findAll();
            }
        }
        return ResponseEntity.ok(ApiResponse.success("Danh sách Phim đề cử thành công", movies));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<Movie>> createMovie(@RequestBody Movie movie) {
        if (movie.getIsHot() == null) {
            movie.setIsHot(true);
        }
        Movie saved = movieRepository.save(movie);
        return ResponseEntity.ok(ApiResponse.success("Thêm phim mới thành công", saved));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<Movie>> updateMovie(
            @PathVariable Integer id, @RequestBody Movie movie) {
        if (!movieRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        movie.setMovieId(id);
        if (movie.getIsHot() == null) {
            movie.setIsHot(true);
        }
        Movie updated = movieRepository.save(movie);
        return ResponseEntity.ok(ApiResponse.success("Cập nhật phim thành công", updated));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ResponseEntity<ApiResponse<Void>> deleteMovie(@PathVariable Integer id) {
        if (!movieRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        movieRepository.deleteById(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa phim thành công"));
    }
}
