package genZ.PRM393GenZ.controller;

import genZ.PRM393GenZ.dto.ApiResponse;
import genZ.PRM393GenZ.entity.Movie;
import genZ.PRM393GenZ.repository.MovieRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
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
        } else {
            movies = movieRepository.findByIsHotTrue();
        }
        return ResponseEntity.ok(ApiResponse.success("Danh sách Phim Hot đề cử thành công", movies));
    }
}
