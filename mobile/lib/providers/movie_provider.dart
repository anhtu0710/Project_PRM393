// lib/providers/movie_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie_model.dart';
import '../services/movie_service.dart';

final movieServiceProvider = Provider((ref) => MovieService());

final movieListProvider =
    StateNotifierProvider<MovieListNotifier, MovieListState>((ref) {
  return MovieListNotifier(ref.watch(movieServiceProvider));
});

class MovieListState {
  final List<MovieModel> movies;
  final bool isLoading;
  final String? error;

  const MovieListState({
    this.movies = const [],
    this.isLoading = false,
    this.error,
  });

  MovieListState copyWith({
    List<MovieModel>? movies,
    bool? isLoading,
    String? error,
  }) {
    return MovieListState(
      movies: movies ?? this.movies,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MovieListNotifier extends StateNotifier<MovieListState> {
  final MovieService _service;

  MovieListNotifier(this._service) : super(const MovieListState()) {
    loadMovies();
  }

  Future<void> loadMovies({String? category}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _service.getMovies(category: category);
      state = state.copyWith(movies: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tải danh sách Phim Hot',
      );
    }
  }
}
