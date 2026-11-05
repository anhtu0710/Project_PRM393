package genZ.PRM393GenZ.repository;

import genZ.PRM393GenZ.entity.TypeRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TypeRoomRepository extends JpaRepository<TypeRoom, String> {
}
