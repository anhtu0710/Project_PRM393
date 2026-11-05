// lib/services/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
      headers: {'Content-Type': 'application/json'},
    ));

    // ── Request interceptor: attach JWT token ────────────────────────────
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        debugPrint('API REQUEST: ${options.method} ${options.uri}');
        final token = await _storage.read(key: AppConfig.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        debugPrint('API ERROR: ${e.type} | ${e.message} | ${e.error} | '
            '${e.requestOptions.uri} | status=${e.response?.statusCode} | '
            'body=${e.response?.data}');
        if (e.response?.statusCode == 401) {
          // Token expired → clear and signal re-login
          await _storage.delete(key: AppConfig.tokenKey);
          await _storage.delete(key: AppConfig.userKey);
        }
        return handler.next(e);
      },
    ));

    // ── Log chi tiết request/response (chỉ ở debug mode) ─────────────────
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }

  static ApiClient get instance => _instance ??= ApiClient._();

  Dio get dio => _dio;
}