package genZ.PRM393GenZ.repository;

import genZ.PRM393GenZ.entity.Room;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface RoomRepository extends JpaRepository<Room, String> {
    List<Room> findByStatus(String status);
    List<Room> findByHotel_HotelId(String hotelId);
    List<Room> findByTypeRoom_TypeRoomId(String typeRoomId);

    @Query("""
            SELECT DISTINCT r FROM Room r
            LEFT JOIN FETCH r.typeRoom tr
            LEFT JOIN FETCH r.hotel h
            WHERE (:keyword IS NULL OR LOWER(r.nameRoom) LIKE LOWER(CONCAT('%', CAST(:keyword AS string), '%'))
                   OR LOWER(tr.typeRoom) LIKE LOWER(CONCAT('%', CAST(:keyword AS string), '%'))
                   OR LOWER(h.name)      LIKE LOWER(CONCAT('%', CAST(:keyword AS string), '%'))
                   OR LOWER(h.address)   LIKE LOWER(CONCAT('%', CAST(:keyword AS string), '%')))
              AND (:hotelId IS NULL OR LOWER(TRIM(h.hotelId)) = LOWER(TRIM(CAST(:hotelId AS string))))
              AND (:typeRoomId IS NULL OR tr.typeRoomId = CAST(:typeRoomId AS string))
              AND (:minPrice IS NULL OR tr.pricePerHour >= :minPrice)
              AND (:maxPrice IS NULL OR tr.pricePerHour <= :maxPrice)
              AND (:checkIn IS NULL OR :checkOut IS NULL OR NOT EXISTS (
                  SELECT b.bookingId FROM Booking b
                  WHERE b.room = r
                    AND b.status IN :blockingStatuses
                    AND b.checkIn < CAST(:checkOut AS timestamp)
                    AND (b.checkOut IS NULL OR b.checkOut > CAST(:checkIn AS timestamp))
              ))
            """)
    List<Room> search(@Param("keyword") String keyword,
                      @Param("hotelId") String hotelId,
                      @Param("typeRoomId") String typeRoomId,
                      @Param("minPrice") BigDecimal minPrice,
                      @Param("maxPrice") BigDecimal maxPrice,
                      @Param("checkIn") LocalDateTime checkIn,
                      @Param("checkOut") LocalDateTime checkOut,
                      @Param("blockingStatuses") List<String> blockingStatuses);
}
