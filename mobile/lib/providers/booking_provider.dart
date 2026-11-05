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

// ── Booking screen state ───────────────────────────────────────────────────────
class BookingState {
  final RoomModel? room;
  final TypeBookingModel? selectedTypeBooking;
  final DateTime selectedDate;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final VoucherModel? appliedVoucher;
  final String note;
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  // Dữ liệu thật từ backend
  final List<TypeBookingModel> typeBookings; // danh sách gói từ server
  final List<VoucherModel> vouchers;     // voucher còn hạn
  final Map<String, double> prices;      // "TYPEROOM|TYPEBOOKING" -> giá

  const BookingState({
    this.room,
    this.selectedTypeBooking,
    required this.selectedDate,
    this.checkIn,
    this.checkOut,
    this.appliedVoucher,
    this.note = '',
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.typeBookings = const [],
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
    if (selectedTypeBooking != null) {
      return selectedTypeBooking!.typeBookingId;
    }
    return 'TB_2H';
  }

  /// Tổng tiền phòng (trước giảm giá voucher), lấy từ bảng PriceConfig
  double get roomTotal {
    final typeRoomId = room?.typeRoom?.typeRoomId.toUpperCase() ?? '';
    final foundPrice = prices['$typeRoomId|$typeBookingId'];
    if (foundPrice != null && foundPrice > 0) return foundPrice;
    
    // Fallback: nếu chưa có cấu hình giá trong PriceConfig, lấy hourly * duration
    final hourlyPrice = room?.typeRoom?.pricePerHour ?? 96000;
    final hours = selectedTypeBooking?.durationHours ?? 2;
    return hourlyPrice * hours;
  }

  /// Số tiền giảm từ voucher
  double get voucherDiscount =>
      appliedVoucher?.calculateDiscount(roomTotal) ?? 0;

  /// Tổng thanh toán cuối
  double get totalPayment =>
      (roomTotal - voucherDiscount).clamp(0, double.infinity);

  /// Mô tả giờ cho combo
  String get comboTimeDesc {
    if (selectedTypeBooking == null) return '';
    final id = selectedTypeBooking!.typeBookingId.toUpperCase();
    if (id == 'TB_DAY') return '07:00 – 12:00';
    if (id == 'TB_NIGHT') return '23:00 – 07:00 (hôm sau)';
    if (selectedTypeBooking!.durationHours != null) {
      return 'Thời lượng: ${selectedTypeBooking!.durationHours} giờ';
    }
    return '';
  }

  BookingState copyWith({
    RoomModel? room,
    TypeBookingModel? selectedTypeBooking,
    DateTime? selectedDate,
    DateTime? checkIn,
    DateTime? checkOut,
    VoucherModel? appliedVoucher,
    String? note,
    bool? isLoading,
    String? error,
    bool? isSuccess,
    List<TypeBookingModel>? typeBookings,
    List<VoucherModel>? vouchers,
    Map<String, double>? prices,
    bool clearVoucher = false,
    bool clearError = false,
    bool clearCheckOut = false,
  }) =>
      BookingState(
        room: room ?? this.room,
        selectedTypeBooking: selectedTypeBooking ?? this.selectedTypeBooking,
        selectedDate: selectedDate ?? this.selectedDate,
        checkIn: checkIn ?? this.checkIn,
        checkOut: clearCheckOut ? null : (checkOut ?? this.checkOut),
        appliedVoucher:
            clearVoucher ? null : (appliedVoucher ?? this.appliedVoucher),
        note: note ?? this.note,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        isSuccess: isSuccess ?? this.isSuccess,
        typeBookings: typeBookings ?? this.typeBookings,
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

  /// Mở màn đặt phòng: reset form cũ, rồi tải bảng giá + gói thuê + voucher từ server
  void setRoom(RoomModel room) {
    state = _initialState().copyWith(room: room);
    _loadPricesAndVouchers();
  }

  Future<void> _loadPricesAndVouchers() async {
    try {
      final prices = await _service.getPrices();
      final vouchers = await _service.getVouchers();
      final typeBookings = await _service.getTypeBookings();
      if (!mounted) return;

      TypeBookingModel? initialCombo;
      if (typeBookings.isNotEmpty) {
        // Ưu tiên chọn combo 2h hoặc phần tử đầu tiên
        initialCombo = typeBookings.firstWhere(
          (tb) => tb.typeBookingId == 'TB_2H',
          orElse: () => typeBookings.first,
        );
      }

      state = state.copyWith(
        prices: prices,
        vouchers: vouchers,
        typeBookings: typeBookings,
        selectedTypeBooking: initialCombo,
      );

      if (initialCombo != null) {
        selectTypeBooking(initialCombo);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
          error: BookingService.errorMessage(e, 'Không tải được bảng giá'));
    }
  }

  void selectTypeBooking(TypeBookingModel combo) {
    final date = state.selectedDate;
    DateTime cin, cout;

    final id = combo.typeBookingId.toUpperCase();
    if (id == 'TB_DAY') {
      cin = DateTime(date.year, date.month, date.day, 7, 0);
      cout = DateTime(date.year, date.month, date.day, 12, 0);
    } else if (id == 'TB_NIGHT') {
      cin = DateTime(date.year, date.month, date.day, 23, 0);
      cout = DateTime(date.year, date.month, date.day + 1, 7, 0);
    } else {
      final oldIn = state.checkIn ?? DateTime.now();
      cin = DateTime(date.year, date.month, date.day, oldIn.hour, oldIn.minute);
      final hours = combo.durationHours ?? 2;
      cout = cin.add(Duration(hours: hours));
    }

    state = state.copyWith(
      selectedTypeBooking: combo,
      checkIn: cin,
      checkOut: cout,
    );
  }

  void setDate(DateTime date) {
    final combo = state.selectedTypeBooking;
    state = state.copyWith(selectedDate: date);
    if (combo != null) {
      selectTypeBooking(combo);
    }
  }

  void setCheckIn(DateTime time) {
    final combo = state.selectedTypeBooking;
    if (combo == null) return;
    
    // Với gói cố định TB_DAY / TB_NIGHT, giờ nhận không đổi thủ công
    final id = combo.typeBookingId.toUpperCase();
    if (id == 'TB_DAY' || id == 'TB_NIGHT') return;

    final date = state.selectedDate;
    final newCheckIn =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final hours = combo.durationHours ?? 2;
    state = state.copyWith(
      checkIn: newCheckIn,
      checkOut: newCheckIn.add(Duration(hours: hours)),
    );
  }

  void setCheckOut(DateTime time) {
    final combo = state.selectedTypeBooking;
    if (combo == null) return;
    
    final id = combo.typeBookingId.toUpperCase();
    if (id == 'TB_DAY' || id == 'TB_NIGHT') return;

    final checkIn = state.checkIn;
    if (checkIn == null) return;
    DateTime picked = DateTime(
        checkIn.year, checkIn.month, checkIn.day, time.hour, time.minute);
    if (!picked.isAfter(checkIn)) {
      picked = picked.add(const Duration(days: 1));
    }
    final hours = combo.durationHours ?? 2;
    state = state.copyWith(checkOut: checkIn.add(Duration(hours: hours)));
  }

  void applyVoucher(VoucherModel voucher) {
    state = state.copyWith(appliedVoucher: voucher);
  }

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

// ── Lịch sử đặt phòng ─────────────────────────────────────────────────────────
final myBookingsProvider =
    FutureProvider.autoDispose<List<BookingModel>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  final list =
      await ref.read(bookingServiceProvider).getBookingsByUser(user.userId);
  list.sort((a, b) {
    final comp = a.checkIn.compareTo(b.checkIn);
    if (comp != 0) return comp;
    return (a.bookingId ?? 0).compareTo(b.bookingId ?? 0);
  });
  return list;
});

// ── Chi tiết 1 booking ─────────────────────────────────────────────────────────
final bookingDetailProvider =
    FutureProvider.autoDispose.family<BookingModel, int>((ref, id) {
  return ref.read(bookingServiceProvider).getBookingById(id);
});

// ── Danh sách tất cả booking dành cho Staff / Admin ──────────────────────────────
final staffBookingsProvider =
    FutureProvider.autoDispose<List<BookingModel>>((ref) async {
  final list = await ref.read(bookingServiceProvider).getAllBookings();
  list.sort((a, b) {
    final comp = a.checkIn.compareTo(b.checkIn);
    if (comp != 0) return comp;
    return (a.bookingId ?? 0).compareTo(b.bookingId ?? 0);
  });
  return list;
});
