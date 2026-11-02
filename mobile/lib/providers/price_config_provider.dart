// lib/providers/price_config_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/price_config_model.dart';
import '../models/room_model.dart';
import '../services/price_config_service.dart';

final priceConfigServiceProvider = Provider<PriceConfigService>((_) => PriceConfigService());

class PriceConfigListState {
  final List<PriceConfigModel> configs;
  final List<TypeRoomModel> typeRooms;
  final List<TypeBookingModel> typeBookings;
  final bool isLoading;
  final String? error;

  const PriceConfigListState({
    this.configs = const [],
    this.typeRooms = const [],
    this.typeBookings = const [],
    this.isLoading = false,
    this.error,
  });

  PriceConfigListState copyWith({
    List<PriceConfigModel>? configs,
    List<TypeRoomModel>? typeRooms,
    List<TypeBookingModel>? typeBookings,
    bool? isLoading,
    String? error,
  }) =>
      PriceConfigListState(
        configs: configs ?? this.configs,
        typeRooms: typeRooms ?? this.typeRooms,
        typeBookings: typeBookings ?? this.typeBookings,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class PriceConfigListNotifier extends StateNotifier<PriceConfigListState> {
  PriceConfigListNotifier(this._service) : super(const PriceConfigListState(isLoading: true)) {
    loadData();
  }

  final PriceConfigService _service;

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final configs = await _service.getAllPriceConfigs();
      final rooms = await _service.getTypeRooms();
      final bookings = await _service.getTypeBookings();
      state = state.copyWith(
        configs: configs,
        typeRooms: rooms,
        typeBookings: bookings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createPriceConfig(PriceConfigModel config) async {
    try {
      await _service.createPriceConfig(config);
      await loadData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updatePriceConfig(int id, PriceConfigModel config) async {
    try {
      await _service.updatePriceConfig(id, config);
      await loadData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deletePriceConfig(int id) async {
    try {
      await _service.deletePriceConfig(id);
      await loadData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final priceConfigListProvider =
    StateNotifierProvider<PriceConfigListNotifier, PriceConfigListState>((ref) {
  return PriceConfigListNotifier(ref.read(priceConfigServiceProvider));
});
