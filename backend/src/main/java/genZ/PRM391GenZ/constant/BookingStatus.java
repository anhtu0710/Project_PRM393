package genZ.PRM391GenZ.constant;

// 6 trạng thái booking. Cả nhóm dùng đúng các tên này, không tự gõ chữ khác.
public class BookingStatus {
    public static final String PENDING    = "PENDING";    // Chờ duyệt
    public static final String CONFIRMED  = "CONFIRMED";  // Đã xác nhận
    public static final String REJECTED   = "REJECTED";   // Bị từ chối
    public static final String CHECKED_IN = "CHECKED_IN"; // Đang ở
    public static final String COMPLETED  = "COMPLETED";  // Hoàn thành
    public static final String CANCELLED  = "CANCELLED";  // Đã huỷ
}
