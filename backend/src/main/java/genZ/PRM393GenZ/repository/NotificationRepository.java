package genZ.PRM393GenZ.repository;

import genZ.PRM393GenZ.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Integer> {
    List<Notification> findByUserId(String userId);
    List<Notification> findByUserIdOrderByNotificationIdDesc(String userId);
}
