// lib/services/voucher_service.dart

import 'package:dio/dio.dart';
import '../models/voucher_model.dart';
import 'api_client.dart';

class VoucherService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<VoucherModel>> getAllVouchers() async {
    final response = await _dio.get('/vouchers');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => VoucherModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VoucherModel> createVoucher(VoucherModel voucher) async {
    final response = await _dio.post('/vouchers', data: voucher.toJson());
    return VoucherModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<VoucherModel> updateVoucher(int id, VoucherModel voucher) async {
    final response = await _dio.put('/vouchers/$id', data: voucher.toJson());
    return VoucherModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteVoucher(int id) async {
    await _dio.delete('/vouchers/$id');
  }
}
