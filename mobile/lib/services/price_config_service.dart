// lib/services/price_config_service.dart

import 'package:dio/dio.dart';
import '../models/price_config_model.dart';
import '../models/room_model.dart';
import 'api_client.dart';

class PriceConfigService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<PriceConfigModel>> getAllPriceConfigs() async {
    final response = await _dio.get('/price-configs');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => PriceConfigModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TypeRoomModel>> getTypeRooms() async {
    final response = await _dio.get('/type-rooms');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => TypeRoomModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TypeBookingModel>> getTypeBookings() async {
    final response = await _dio.get('/type-bookings');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => TypeBookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PriceConfigModel> createPriceConfig(PriceConfigModel config) async {
    final response = await _dio.post('/price-configs', data: config.toJson());
    return PriceConfigModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PriceConfigModel> updatePriceConfig(int id, PriceConfigModel config) async {
    final response = await _dio.put('/price-configs/$id', data: config.toJson());
    return PriceConfigModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deletePriceConfig(int id) async {
    await _dio.delete('/price-configs/$id');
  }
}
