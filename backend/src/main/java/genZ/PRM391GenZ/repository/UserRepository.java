package genZ.PRM391GenZ.repository;

import genZ.PRM391GenZ.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, String> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);

    Optional<User> findByPhone(String phone);
    boolean existsByPhone(String phone);

    List<User> findByRole_RoleId(String roleId);
    List<User> findByHotel_HotelIdAndRole_RoleId(String hotelId, String roleId);
}
