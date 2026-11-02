// lib/services/hotel_service.dart

import 'package:dio/dio.dart';
import '../models/room_model.dart';
import 'api_client.dart';

class HotelService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<HotelModel>> getAllHotels() async {
    final response = await _dio.get('/hotels');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => HotelModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HotelModel> createHotel(HotelModel hotel) async {
    final response = await _dio.post('/hotels', data: hotel.toJson());
    return HotelModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<HotelModel> updateHotel(String id, HotelModel hotel) async {
    final response = await _dio.put('/hotels/$id', data: hotel.toJson());
    return HotelModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteHotel(String id) async {
    await _dio.delete('/hotels/$id');
  }
}
