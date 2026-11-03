package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.Notification;
import genZ.PRM391GenZ.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationRepository notificationRepository;

    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<Notification>>> getNotificationsByUserId(@PathVariable String userId) {
        List<Notification> list = notificationRepository.findByUserId(userId);
        return ResponseEntity.ok(ApiResponse.success("Danh sách thông báo", list));
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<ApiResponse<Notification>> markAsRead(@PathVariable Integer id) {
        return notificationRepository.findById(id)
                .map(notif -> {
                    notif.setRead(true);
                    Notification updated = notificationRepository.save(notif);
                    return ResponseEntity.ok(ApiResponse.success("Đã đọc thông báo", updated));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/user/{userId}/read-all")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead(@PathVariable String userId) {
        List<Notification> list = notificationRepository.findByUserId(userId);
        for (Notification notif : list) {
            notif.setRead(true);
        }
        notificationRepository.saveAll(list);
        return ResponseEntity.ok(ApiResponse.success("Đã đánh dấu tất cả là đã đọc"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteNotification(@PathVariable Integer id) {
        if (!notificationRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        notificationRepository.deleteById(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa thông báo thành công"));
    }
}
