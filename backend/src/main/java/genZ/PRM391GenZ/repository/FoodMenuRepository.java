package genZ.PRM391GenZ.repository;

import genZ.PRM391GenZ.entity.FoodMenu;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FoodMenuRepository extends JpaRepository<FoodMenu, Integer> {
    List<FoodMenu> findByIsAvailableTrue();
    List<FoodMenu> findByCategoryAndIsAvailableTrue(String category);
}
