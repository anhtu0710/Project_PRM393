package genZ.PRM393GenZ.repository;

import genZ.PRM393GenZ.entity.TypeBooking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TypeBookingRepository extends JpaRepository<TypeBooking, String> {
}
