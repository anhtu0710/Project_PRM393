package genZ.PRM393GenZ.repository;

import genZ.PRM393GenZ.entity.Hotel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface HotelRepository extends JpaRepository<Hotel, String> {
}

