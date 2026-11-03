// lib/providers/food_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_menu_model.dart';
import '../services/food_service.dart';

final foodServiceProvider = Provider((ref) => FoodService());

final foodMenuListProvider =
    StateNotifierProvider<FoodMenuNotifier, FoodMenuState>((ref) {
  return FoodMenuNotifier(ref.watch(foodServiceProvider));
});

class FoodMenuState {
  final List<FoodMenuModel> items;
  final bool isLoading;
  final String? error;

  const FoodMenuState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  FoodMenuState copyWith({
    List<FoodMenuModel>? items,
    bool? isLoading,
    String? error,
  }) {
    return FoodMenuState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FoodMenuNotifier extends StateNotifier<FoodMenuState> {
  final FoodService _service;

  FoodMenuNotifier(this._service) : super(const FoodMenuState()) {
    loadFoodMenu();
  }

  Future<void> loadFoodMenu({String? category}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _service.getFoodMenu(category: category);
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tải thực đơn F&B',
      );
    }
  }
}
