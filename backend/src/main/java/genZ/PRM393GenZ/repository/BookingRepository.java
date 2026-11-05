package genZ.PRM393GenZ.repository;

import genZ.PRM393GenZ.entity.Booking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BookingRepository extends JpaRepository<Booking, Integer> {
    List<Booking> findByUser_UserId(String userId);
    List<Booking> findByRoom_RoomId(String roomId);
    List<Booking> findByStatus(String status);
    List<Booking> findByUser_UserIdAndStatusOrderByCheckOutDesc(String userId, String status);
}
