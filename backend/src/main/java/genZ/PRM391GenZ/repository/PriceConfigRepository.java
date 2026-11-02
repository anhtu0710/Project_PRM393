package genZ.PRM391GenZ.repository;

import genZ.PRM391GenZ.entity.PriceConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PriceConfigRepository extends JpaRepository<PriceConfig, Integer> {
    List<PriceConfig> findByTypeRoom_TypeRoomIdOrderByTypeBooking_DurationHoursAsc(String typeRoomId);
}
