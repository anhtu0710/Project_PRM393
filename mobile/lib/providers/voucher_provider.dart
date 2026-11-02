// lib/providers/voucher_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voucher_model.dart';
import '../services/voucher_service.dart';

final voucherServiceProvider = Provider<VoucherService>((_) => VoucherService());

class VoucherListState {
  final List<VoucherModel> vouchers;
  final bool isLoading;
  final String? error;

  const VoucherListState({
    this.vouchers = const [],
    this.isLoading = false,
    this.error,
  });

  VoucherListState copyWith({
    List<VoucherModel>? vouchers,
    bool? isLoading,
    String? error,
  }) =>
      VoucherListState(
        vouchers: vouchers ?? this.vouchers,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class VoucherListNotifier extends StateNotifier<VoucherListState> {
  VoucherListNotifier(this._service) : super(const VoucherListState(isLoading: true)) {
    loadVouchers();
  }

  final VoucherService _service;

  Future<void> loadVouchers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _service.getAllVouchers();
      state = state.copyWith(vouchers: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createVoucher(VoucherModel voucher) async {
    try {
      await _service.createVoucher(voucher);
      await loadVouchers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateVoucher(int id, VoucherModel voucher) async {
    try {
      await _service.updateVoucher(id, voucher);
      await loadVouchers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteVoucher(int id) async {
    try {
      await _service.deleteVoucher(id);
      await loadVouchers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final voucherListProvider =
    StateNotifierProvider<VoucherListNotifier, VoucherListState>((ref) {
  return VoucherListNotifier(ref.read(voucherServiceProvider));
});
