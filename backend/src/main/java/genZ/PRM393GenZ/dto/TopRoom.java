package genZ.PRM393GenZ.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

// 1 dòng trong bảng "phòng được đặt nhiều nhất"
@Data
@AllArgsConstructor
public class TopRoom {
    private String roomId;
    private String roomName;
    private String hotelName;
    private int bookingCount;
}
