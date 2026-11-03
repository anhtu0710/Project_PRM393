// lib/services/movie_service.dart

import 'package:dio/dio.dart';
import '../models/movie_model.dart';
import 'api_client.dart';

class MovieService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<MovieModel>> getMovies({String? category}) async {
    try {
      final response = await _dio.get(
        '/movies',
        queryParameters: {
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'] as List<dynamic>;
        return data
            .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
