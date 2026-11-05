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
    // Luôn gọi GET /rooms không kèm query parameters (giống hệt cơ chế màn Staff),
    // việc lọc chi nhánh/loại phòng sẽ thực hiện 100% cục bộ trên client.
    final response = await _dio.get('/rooms');
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

  Future<RoomModel> createRoom(RoomModel room) async {
    final response = await _dio.post('/rooms', data: room.toJson());
    return RoomModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<RoomModel> updateRoom(String id, RoomModel room) async {
    final response = await _dio.put('/rooms/$id', data: room.toJson());
    return RoomModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteRoom(String id) async {
    final response = await _dio.delete('/rooms/$id');
    if (response.data['success'] == false) {
      throw Exception(response.data['message'] ?? 'Xóa phòng thất bại');
    }
  }

  Future<List<TypeRoomModel>> getTypeRooms() async {
    final response = await _dio.get('/type-rooms');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => TypeRoomModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
