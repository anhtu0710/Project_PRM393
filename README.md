# GenzCinema Hotel

Ứng dụng đặt phòng **khách sạn - rạp chiếu phim mini** (môn PRM393), viết bằng **Flutter**.

Ở nhánh `sqlite`, app **không cần server**: toàn bộ dữ liệu nằm trong database **SQLite ngay trên điện thoại**. Chỉ cần cài file APK là dùng được, không cần mạng, không cần bật laptop.

> Bản dùng Spring Boot + SQL Server nằm ở nhánh `main`.

---

## 1. Tính năng

App có 3 loại tài khoản, đăng nhập xong sẽ tự vào đúng màn hình của mình.

### Khách (chưa đăng nhập)
- Xem trang chủ, danh sách phòng, chi tiết phòng (bảng giá theo combo, điểm đánh giá, nhận xét).
- Lọc phòng theo chi nhánh, loại phòng, mức giá, giờ trống.
- Lưu phòng yêu thích.
- Bấm **Đặt phòng** thì app chuyển sang trang đăng nhập.

### Khách hàng (CUSTOMER)
- Đăng ký, đăng nhập, quên mật khẩu.
- Đặt phòng theo giờ (2h / 4h / 5h / 6h), combo ngày, combo đêm.
  - Giá lấy từ bảng giá.
  - Không cho đặt trùng giờ với người khác.
  - Áp mã voucher (kiểm tra hạn dùng và đơn tối thiểu).
- Lịch sử đặt phòng 3 tab: Sắp tới, Đã qua, Đã huỷ. Huỷ booking khi còn chờ duyệt hoặc đã xác nhận.
- Đánh giá phòng 1–5 sao sau khi đã trả phòng.

### Nhân viên (STAFF)
- Duyệt / từ chối booking, check-in, check-out.
- Sơ đồ phòng theo trạng thái: Trống, Đang dùng, Đang dọn.
- Thêm, sửa, xoá phòng và chi nhánh. Không xoá được khi còn booking đang hoạt động.
- Sửa bảng giá, tạo gói combo mới.
- Tạo, sửa, xoá voucher.

### Quản trị (ADMIN)
- Dashboard thống kê theo 7 ngày / 8 tuần / 6 tháng: doanh thu, số booking, tỉ lệ lấp phòng, biểu đồ, top phòng đặt nhiều.
- Quản lý người dùng: tìm kiếm, đổi role Khách hàng ↔ Nhân viên, khoá / mở khoá tài khoản.

---

## 2. Tài khoản dùng thử

Mật khẩu chung cho cả 3 tài khoản: **`Genz@123`**

| Vai trò | Email |
|---|---|
| Quản trị | `admin@genz.test` |
| Nhân viên | `staff@genz.test` |
| Khách hàng | `customer@genz.test` |

Dữ liệu mẫu có sẵn:
- 9 chi nhánh ở Hà Nội, 36 phòng (Queen / King).
- Bảng giá 6 gói combo.
- 3 voucher:
  - `GENZ10`: giảm 10%.
  - `GIAM50K`: giảm 50.000đ cho đơn từ 250.000đ.
  - `HETHAN`: đã hết hạn, dùng để thử báo lỗi.
- Vài booking mẫu của `customer@genz.test`. Ngày của chúng tính theo ngày cài app, nên dashboard lúc nào cũng có số liệu.

---

## 3. Cài nhanh bằng file APK (không cần cài gì thêm)

1. Lấy file `app-release.apk` (nhóm gửi, hoặc tự build theo mục 4.4).
2. Chép vào điện thoại Android rồi mở file đó.
3. Nếu máy hỏi, cho phép **"Cài ứng dụng từ nguồn không xác định"**.
4. Mở app **GenzCinema Hotel** và đăng nhập bằng tài khoản ở mục 2.

---

## 4. Chạy từ mã nguồn

### 4.1. Cần cài trước
- **Flutter SDK** 3.x (nhóm đang dùng 3.47): https://docs.flutter.dev/get-started/install
- **Android Studio** (để có Android SDK và máy ảo Android).
- **Git**.

Kiểm tra đã cài đủ chưa:

```bash
flutter doctor
```

Dòng **Android toolchain** phải có dấu ✓.

### 4.2. Lấy code

```bash
git clone <link repo của nhóm>
```

```bash
cd Project_PRM393
```

```bash
git checkout sqlite
```

```bash
cd mobile
```

```bash
flutter pub get
```

### 4.3. Chạy trên máy ảo hoặc điện thoại

> ⚠️ Bản này **không chạy trên Chrome** (thư viện SQLite `sqflite` chỉ hỗ trợ Android / iOS). Hãy dùng máy ảo Android hoặc điện thoại thật.

**Cách 1 – Máy ảo Android:**

Xem danh sách máy ảo:

```bash
flutter emulators
```

Bật máy ảo (thay `Medium_Phone` bằng tên máy ảo của bạn):

```bash
flutter emulators --launch Medium_Phone
```

Đợi máy ảo khởi động xong rồi chạy app:

```bash
flutter run
```

**Cách 2 – Điện thoại thật:**
1. Bật **Tuỳ chọn nhà phát triển** → **Gỡ lỗi USB** trên điện thoại.
2. Cắm cáp vào máy tính.
3. Chạy `flutter devices` để xem máy đã nhận chưa, rồi chạy `flutter run`.

### 4.4. Build file APK

```bash
flutter build apk
```

File nằm ở `mobile/build/app/outputs/flutter-apk/app-release.apk`.

---

## 5. Cấu trúc dự án

```
mobile/
├── assets/
│   ├── database.sql          ← TẤT CẢ bảng + dữ liệu mẫu (SQLite)
│   └── images/               ← ảnh banner, logo
└── lib/
    ├── main.dart             ← điểm bắt đầu của app
    ├── config/
    │   ├── router.dart       ← điều hướng màn hình + chặn quyền theo role
    │   ├── app_config.dart   ← tên role, trạng thái booking / phòng
    │   └── app_theme.dart    ← màu sắc, font
    ├── database/
    │   └── database_helper.dart  ← mở database, lần đầu chạy file database.sql
    ├── models/               ← các class dữ liệu (Room, Booking, Voucher, ...)
    ├── services/             ← đọc / ghi SQLite + luật nghiệp vụ (giá, trùng giờ, voucher, thống kê)
    ├── providers/            ← Riverpod: giữ trạng thái, gọi service
    ├── screens/              ← giao diện, chia theo role
    │   ├── auth/             ← đăng nhập, đăng ký, quên mật khẩu
    │   ├── home/             ← trang chủ
    │   ├── customer/         ← phòng, đặt phòng, lịch sử, đánh giá, đã lưu
    │   ├── staff/            ← màn hình nhân viên
    │   └── admin/            ← dashboard, quản lý người dùng
    └── widgets/              ← widget dùng chung (thanh điều hướng dưới)
```

**Luồng dữ liệu:** Màn hình → Provider → Service → SQLite

Ví dụ khi khách bấm Đặt phòng:
1. `booking_screen.dart` gọi `bookingProvider`.
2. Provider gọi `BookingService.createBooking()`.
3. Service kiểm tra phòng, trùng giờ, tính giá và voucher, rồi `INSERT` vào bảng `Booking`.

### Công nghệ

| Phần | Dùng gì |
|---|---|
| Giao diện | Flutter (Material 3) |
| Quản lý trạng thái | Riverpod |
| Điều hướng | GoRouter |
| Database | SQLite (`sqflite`) |
| Mã hoá mật khẩu | SHA-256 (`crypto`) |
| Lưu người đang đăng nhập | `flutter_secure_storage` |
| Lưu phòng yêu thích | `shared_preferences` |
| Biểu đồ | `fl_chart` |

---

## 6. Database

Có 12 bảng, giống thiết kế SQL Server cũ:

`Role`, `User`, `Hotel`, `Room`, `TypeRoom`, `TypeBooking`, `PriceConfig`, `Booking`, `Voucher`, `Review`, `Notification`, `PasswordResetToken`.

- Trạng thái booking: `PENDING` (chờ duyệt), `CONFIRMED` (đã xác nhận), `REJECTED` (bị từ chối), `CHECKED_IN` (đang ở), `COMPLETED` (hoàn thành), `CANCELLED` (đã huỷ).
- Trạng thái phòng: `Trống`, `Đang dùng`, `Đang dọn`.

**Muốn sửa bảng hoặc dữ liệu mẫu:**
1. Sửa file `mobile/assets/database.sql`.
2. **Gỡ app khỏi máy** rồi chạy / cài lại. File SQL chỉ chạy 1 lần lúc database chưa có.

Không viết dấu `;` trong dữ liệu hay chú thích, vì app tách các câu lệnh theo dấu `;`.

---

## 7. Lưu ý

- **Mỗi điện thoại có dữ liệu riêng.** Đặt phòng trên máy A thì máy B không thấy.
- **Gỡ app là mất dữ liệu.** Cài lại sẽ về dữ liệu mẫu ban đầu.
- **Quên mật khẩu:** bản offline không gửi được email. Nhập email xong, app mở luôn trang đặt mật khẩu mới.
- Màn **Thông báo** và nút **Feedback** ở trang chủ chưa làm xong.

---

## 8. Gặp lỗi thường gặp

| Lỗi | Cách sửa |
|---|---|
| `flutter run` báo không có thiết bị | Bật máy ảo trước (`flutter emulators --launch ...`) hoặc cắm điện thoại và bật Gỡ lỗi USB. |
| Chạy trên Chrome bị lỗi database | Bản SQLite không hỗ trợ web, hãy chạy trên Android. |
| Sửa `database.sql` mà app không đổi | Gỡ app rồi cài lại. |
| Cài APK bị chặn | Cho phép cài ứng dụng từ nguồn không xác định trong Cài đặt. |
| Lỗi thư viện sau khi `git pull` | Chạy `flutter pub get` lại trong thư mục `mobile`. |
