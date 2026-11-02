// lib/services/room_service.dart

import 'package:dio/dio.dart';
import '../models/room_model.dart';
import 'api_client.dart';

class RoomService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<RoomModel>> getAllRooms({
    String? keyword,
    String? hotelId,
    String? typeRoomId,
    double? minPrice,
    double? maxPrice,
    DateTime? checkIn,
    DateTime? checkOut,
  }) async {
    final response = await _dio.get('/rooms', queryParameters: {
      if (keyword != null && keyword.trim().isNotEmpty)
        'keyword': keyword.trim(),
      if (hotelId != null) 'hotelId': hotelId,
      if (typeRoomId != null) 'typeRoomId': typeRoomId,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (checkIn != null) 'checkIn': checkIn.toIso8601String(),
      if (checkOut != null) 'checkOut': checkOut.toIso8601String(),
    });
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RoomModel> getRoomById(String id) async {
    final response = await _dio.get('/rooms/$id');
    return RoomModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<RoomModel>> getAvailableRooms() async {
    final response = await _dio.get('/rooms/available');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
