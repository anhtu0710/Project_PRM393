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

  Future<MovieModel> createMovie(MovieModel movie) async {
    final response = await _dio.post('/movies', data: movie.toJson());
    return MovieModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<MovieModel> updateMovie(int id, MovieModel movie) async {
    final response = await _dio.put('/movies/$id', data: movie.toJson());
    return MovieModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteMovie(int id) async {
    await _dio.delete('/movies/$id');
  }
}
