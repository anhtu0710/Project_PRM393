// lib/services/food_service.dart

import 'package:dio/dio.dart';
import '../models/food_menu_model.dart';
import 'api_client.dart';

class FoodService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<FoodMenuModel>> getFoodMenu({String? category}) async {
    final response = await _dio.get(
      '/food-menu',
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    if (response.data != null && response.data['data'] != null) {
      final data = response.data['data'] as List<dynamic>;
      return data
          .map((e) => FoodMenuModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
