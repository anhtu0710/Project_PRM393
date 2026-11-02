package genZ.PRM391GenZ.repository;

import genZ.PRM391GenZ.entity.PriceConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PriceConfigRepository extends JpaRepository<PriceConfig, Integer> {
    List<PriceConfig> findByTypeRoom_TypeRoomIdOrderByTypeBooking_DurationHoursAsc(String typeRoomId);

    // Giá của 1 loại phòng với 1 combo, VD: ("QUEEN", "TB_2H")
    Optional<PriceConfig> findByTypeRoom_TypeRoomIdAndTypeBooking_TypeBookingId(
            String typeRoomId, String typeBookingId);
}
