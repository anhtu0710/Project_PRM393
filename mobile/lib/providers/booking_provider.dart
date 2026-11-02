// lib/providers/booking_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../models/booking_model.dart';
import '../models/room_model.dart';
import '../services/booking_service.dart';
import 'auth_provider.dart';

// ── Service provider ───────────────────────────────────────────────────────────
final bookingServiceProvider =
    Provider<BookingService>((_) => BookingService());

// ── Combo types ────────────────────────────────────────────────────────────────
enum BookingComboType {
  hourly,  // Theo giờ (2h / 4h / 5h / 6h)
  day,     // Combo ngày (7h-12h)
  night,   // Combo đêm (23h-7h sáng hôm sau)
}

const Map<BookingComboType, String> comboLabels = {
  BookingComboType.hourly: 'Theo giờ',
  BookingComboType.day: 'Combo ngày',
  BookingComboType.night: 'Combo đêm',
};

// Các gói theo giờ trong bảng TypeBooking (số giờ -> TypeBookingId)
const Map<int, String> hourlyTypeBookingIds = {
  2: 'TB_2H',
  4: 'TB_4H',
  5: 'TB_5H',
  6: 'TB_6H',
};

// ── Booking screen state ───────────────────────────────────────────────────────
class BookingState {
  final RoomModel? room;
  final BookingComboType selectedCombo;
  final DateTime selectedDate;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final VoucherModel? appliedVoucher;
  final String note;
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  // Dữ liệu thật từ backend
  final List<VoucherModel> vouchers;     // voucher còn hạn
  final Map<String, double> prices;      // "TYPEROOM|TYPEBOOKING" -> giá

  const BookingState({
    this.room,
    this.selectedCombo = BookingComboType.hourly,
    required this.selectedDate,
    this.checkIn,
    this.checkOut,
    this.appliedVoucher,
    this.note = '',
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.vouchers = const [],
    this.prices = const {},
  });

  /// Số giờ khách chọn ở chế độ Theo giờ
  int get selectedHours {
    if (checkIn == null || checkOut == null) return 2;
    return (checkOut!.difference(checkIn!).inMinutes / 60).ceil();
  }

  /// TypeBookingId gửi lên server (server dựa vào đây để tính giá + giờ ra)
  String get typeBookingId {
    switch (selectedCombo) {
      case BookingComboType.day:
        return 'TB_DAY';
      case BookingComboType.night:
        return 'TB_NIGHT';
      case BookingComboType.hourly:
        return hourlyTypeBookingIds[selectedHours] ?? 'TB_2H';
    }
  }

  /// Tổng tiền phòng (trước giảm giá voucher), lấy từ bảng PriceConfig
  double get roomTotal {
    final typeRoomId = room?.typeRoom?.typeRoomId.toUpperCase() ?? '';
    return prices['$typeRoomId|$typeBookingId'] ?? 0;
  }

  /// Số tiền giảm từ voucher
  double get voucherDiscount =>
      appliedVoucher?.calculateDiscount(roomTotal) ?? 0;

  /// Tổng thanh toán cuối
  double get totalPayment =>
      (roomTotal - voucherDiscount).clamp(0, double.infinity);

  /// Mô tả giờ cho combo
  String get comboTimeDesc {
    switch (selectedCombo) {
      case BookingComboType.day:
        return '07:00 – 12:00';
      case BookingComboType.night:
        return '23:00 – 07:00 (hôm sau)';
      default:
        return '';
    }
  }

  BookingState copyWith({
    RoomModel? room,
    BookingComboType? selectedCombo,
    DateTime? selectedDate,
    DateTime? checkIn,
    DateTime? checkOut,
    VoucherModel? appliedVoucher,
    String? note,
    bool? isLoading,
    String? error,
    bool? isSuccess,
    List<VoucherModel>? vouchers,
    Map<String, double>? prices,
    bool clearVoucher = false,
    bool clearError = false,
    bool clearCheckOut = false,
  }) =>
      BookingState(
        room: room ?? this.room,
        selectedCombo: selectedCombo ?? this.selectedCombo,
        selectedDate: selectedDate ?? this.selectedDate,
        checkIn: checkIn ?? this.checkIn,
        checkOut: clearCheckOut ? null : (checkOut ?? this.checkOut),
        appliedVoucher:
            clearVoucher ? null : (appliedVoucher ?? this.appliedVoucher),
        note: note ?? this.note,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        isSuccess: isSuccess ?? this.isSuccess,
        vouchers: vouchers ?? this.vouchers,
        prices: prices ?? this.prices,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────────
class BookingNotifier extends StateNotifier<BookingState> {
  final BookingService _service;

  BookingNotifier(this._service) : super(_initialState());

  static BookingState _initialState() {
    final now = DateTime.now();
    final checkIn = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
    return BookingState(
      selectedDate: DateTime(now.year, now.month, now.day),
      checkIn: checkIn,
      checkOut: checkIn.add(const Duration(hours: 2)),
    );
  }

  /// Mở màn đặt phòng: reset form cũ, rồi tải bảng giá + voucher từ server
  void setRoom(RoomModel room) {
    state = _initialState().copyWith(room: room);
    _loadPricesAndVouchers();
  }

  Future<void> _loadPricesAndVouchers() async {
    try {
      final prices = await _service.getPrices();
      final vouchers = await _service.getVouchers();
      if (!mounted) return;
      state = state.copyWith(prices: prices, vouchers: vouchers);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
          error: BookingService.errorMessage(e, 'Không tải được bảng giá'));
    }
  }

  void setCombo(BookingComboType combo) {
    final date = state.selectedDate;
    DateTime cin, cout;

    switch (combo) {
      case BookingComboType.day:
        cin = DateTime(date.year, date.month, date.day, 7, 0);
        cout = DateTime(date.year, date.month, date.day, 12, 0);
        break;
      case BookingComboType.night:
        cin = DateTime(date.year, date.month, date.day, 23, 0);
        cout = DateTime(date.year, date.month, date.day + 1, 7, 0);
        break;
      case BookingComboType.hourly:
        // Giữ giờ đang chọn nhưng chuyển sang ngày đang chọn
        final oldIn = state.checkIn ?? DateTime.now();
        cin = DateTime(date.year, date.month, date.day, oldIn.hour, oldIn.minute);
        final hours = state.selectedCombo == BookingComboType.hourly
            ? _snapHours(state.selectedHours)
            : 2;
        cout = cin.add(Duration(hours: hours));
        break;
    }

    state = state.copyWith(
      selectedCombo: combo,
      checkIn: cin,
      checkOut: cout,
    );
  }

  void setDate(DateTime date) {
    final combo = state.selectedCombo;
    state = state.copyWith(selectedDate: date);
    // Re-apply combo logic với ngày mới
    setCombo(combo);
  }

  void setCheckIn(DateTime time) {
    // Chỉ cho phép thay đổi khi ở chế độ Theo giờ
    if (state.selectedCombo != BookingComboType.hourly) return;
    final date = state.selectedDate;
    final newCheckIn =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    // Giữ nguyên số giờ đã chọn
    final hours = _snapHours(state.selectedHours);
    state = state.copyWith(
      checkIn: newCheckIn,
      checkOut: newCheckIn.add(Duration(hours: hours)),
    );
  }

  void setCheckOut(DateTime time) {
    if (state.selectedCombo != BookingComboType.hourly) return;
    final checkIn = state.checkIn;
    if (checkIn == null) return;
    DateTime picked = DateTime(
        checkIn.year, checkIn.month, checkIn.day, time.hour, time.minute);
    // Nếu checkout <= checkin, thêm 1 ngày (qua đêm)
    if (!picked.isAfter(checkIn)) {
      picked = picked.add(const Duration(days: 1));
    }
    // Làm tròn lên gói gần nhất (2h/4h/5h/6h) vì server tính giờ ra theo gói
    final hours = _snapHours((picked.difference(checkIn).inMinutes / 60).ceil());
    state = state.copyWith(checkOut: checkIn.add(Duration(hours: hours)));
  }

  /// Chọn gói theo giờ nhỏ nhất mà vẫn đủ số giờ (tối đa 6h)
  static int _snapHours(int hours) {
    for (final h in hourlyTypeBookingIds.keys) {
      if (h >= hours) return h;
    }
    return hourlyTypeBookingIds.keys.last;
  }

  void applyVoucher(VoucherModel voucher) {
    state = state.copyWith(appliedVoucher: voucher);
  }

  /// Nhập mã tay: hỏi server. Trả về câu lỗi, hoặc null nếu áp dụng được.
  Future<String?> applyVoucherCode(String code) async {
    if (code.isEmpty) return 'Vui lòng nhập mã voucher';
    try {
      final voucher = await _service.checkVoucher(code, state.roomTotal);
      state = state.copyWith(appliedVoucher: voucher);
      return null;
    } catch (e) {
      return BookingService.errorMessage(e, 'Mã voucher không hợp lệ');
    }
  }

  void removeVoucher() {
    state = state.copyWith(clearVoucher: true);
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  Future<bool> submitBooking(String userId) async {
    if (state.room == null || state.checkIn == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Giá, giờ ra, giảm giá: server tự tính lại, ở đây chỉ gửi để tham khảo
      final booking = BookingModel(
        roomId: state.room!.roomId,
        userId: userId,
        typeBookingId: state.typeBookingId,
        checkIn: state.checkIn!,
        checkOut: state.checkOut,
        totalPrice: state.totalPayment,
        status: AppConfig.bookingPending,
        voucherCode: state.appliedVoucher?.code,
        discountAmount:
            state.voucherDiscount > 0 ? state.voucherDiscount : null,
        note: state.note.isNotEmpty ? state.note : null,
      );
      await _service.createBooking(booking);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: BookingService.errorMessage(
              e, 'Đặt phòng thất bại. Vui lòng thử lại!'));
      return false;
    }
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────
final bookingProvider =
    StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier(ref.read(bookingServiceProvider));
});

// ── Lịch sử đặt phòng của khách đang đăng nhập ─────────────────────────────────
// Gọi ref.invalidate(myBookingsProvider) để tải lại (VD: sau khi huỷ).
final myBookingsProvider =
    FutureProvider.autoDispose<List<BookingModel>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  final list =
      await ref.read(bookingServiceProvider).getBookingsByUser(user.userId);
  // Mới nhất lên đầu
  list.sort((a, b) => b.checkIn.compareTo(a.checkIn));
  return list;
});

// ── Chi tiết 1 booking ─────────────────────────────────────────────────────────
final bookingDetailProvider =
    FutureProvider.autoDispose.family<BookingModel, int>((ref, id) {
  return ref.read(bookingServiceProvider).getBookingById(id);
});
