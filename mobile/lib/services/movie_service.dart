// lib/services/movie_service.dart
// Phim hot đề cử — đọc bảng Movie trong SQLite

import '../database/database_helper.dart';
import '../models/movie_model.dart';

class MovieService {
  Future<List<MovieModel>> getMovies({String? category}) async {
    final db = await DatabaseHelper.database;
    final rows = (category != null && category.isNotEmpty)
        ? await db.query('Movie', where: 'Category = ?', whereArgs: [category])
        : await db.query('Movie');

    return rows
        .map((r) => MovieModel(
              movieId: r['MovieId'] as int,
              title: r['Title'] as String? ?? '',
              category: r['Category'] as String? ?? '',
              rating: (r['Rating'] as num?)?.toDouble() ?? 5.0,
              quality: r['Quality'] as String? ?? '4K Netflix',
              posterUrl: r['PosterUrl'] as String?,
              description: r['Description'] as String?,
              isHot: r['IsHot'] == 1,
            ))
        .toList();
  }
}
