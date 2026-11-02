// lib/providers/hotel_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room_model.dart';
import '../services/hotel_service.dart';

final hotelServiceProvider = Provider<HotelService>((_) => HotelService());

class HotelListState {
  final List<HotelModel> hotels;
  final bool isLoading;
  final String? error;

  const HotelListState({
    this.hotels = const [],
    this.isLoading = false,
    this.error,
  });

  HotelListState copyWith({
    List<HotelModel>? hotels,
    bool? isLoading,
    String? error,
  }) =>
      HotelListState(
        hotels: hotels ?? this.hotels,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class HotelListNotifier extends StateNotifier<HotelListState> {
  HotelListNotifier(this._service) : super(const HotelListState(isLoading: true)) {
    loadHotels();
  }

  final HotelService _service;

  Future<void> loadHotels() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _service.getAllHotels();
      state = state.copyWith(hotels: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createHotel(HotelModel hotel) async {
    try {
      await _service.createHotel(hotel);
      await loadHotels();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateHotel(String id, HotelModel hotel) async {
    try {
      await _service.updateHotel(id, hotel);
      await loadHotels();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteHotel(String id) async {
    try {
      await _service.deleteHotel(id);
      await loadHotels();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final hotelListProvider =
    StateNotifierProvider<HotelListNotifier, HotelListState>((ref) {
  return HotelListNotifier(ref.read(hotelServiceProvider));
});
