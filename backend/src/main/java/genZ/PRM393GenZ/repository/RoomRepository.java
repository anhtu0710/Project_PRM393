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

    @Query(value = """
            SELECT DISTINCT r.* FROM room r
            LEFT JOIN typeroom tr ON tr.TypeRoomId = r.TypeRoomId
            LEFT JOIN hotel h ON h.HotelId = r.HotelId
            WHERE (:keyword = '' OR LOWER(r.nameRoom) LIKE LOWER(CONCAT('%', CAST(:keyword AS TEXT), '%'))
                   OR LOWER(tr.TypeRoom) LIKE LOWER(CONCAT('%', CAST(:keyword AS TEXT), '%'))
                   OR LOWER(h.name)      LIKE LOWER(CONCAT('%', CAST(:keyword AS TEXT), '%'))
                   OR LOWER(h.address)   LIKE LOWER(CONCAT('%', CAST(:keyword AS TEXT), '%')))
              AND (:hotelId = '' OR LOWER(TRIM(h.HotelId)) = LOWER(TRIM(CAST(:hotelId AS TEXT))))
              AND (:typeRoomId = '' OR tr.TypeRoomId = CAST(:typeRoomId AS TEXT))
              AND (:minPrice = 0 OR tr.pricePerHour >= CAST(:minPrice AS NUMERIC))
              AND (:maxPrice = 0 OR tr.pricePerHour <= CAST(:maxPrice AS NUMERIC))
            """, nativeQuery = true)
    List<Room> search(@Param("keyword") String keyword,
                      @Param("hotelId") String hotelId,
                      @Param("typeRoomId") String typeRoomId,
                      @Param("minPrice") BigDecimal minPrice,
                      @Param("maxPrice") BigDecimal maxPrice,
                      @Param("checkIn") LocalDateTime checkIn,
                      @Param("checkOut") LocalDateTime checkOut,
                      @Param("blockingStatuses") List<String> blockingStatuses);
}
