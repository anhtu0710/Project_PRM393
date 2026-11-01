package genZ.PRM391GenZ.repository;

import genZ.PRM391GenZ.entity.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReviewRepository extends JpaRepository<Review, Integer> {
    List<Review> findByRoomId(String roomId);
    boolean existsByBookingId(Integer bookingId);
}
