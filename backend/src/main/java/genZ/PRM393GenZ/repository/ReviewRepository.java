package genZ.PRM393GenZ.repository;

import genZ.PRM393GenZ.entity.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReviewRepository extends JpaRepository<Review, Integer> {
    List<Review> findByRoom_RoomIdOrderByCreatedAtDesc(String roomId);
    List<Review> findByRoom_RoomId(String roomId);
    boolean existsByBooking_BookingId(Integer bookingId);
}
