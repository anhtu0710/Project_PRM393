// lib/models/movie_model.dart

class MovieModel {
  final int movieId;
  final String title;
  final String category;
  final double rating;
  final String quality;
  final String? posterUrl;
  final String? description;
  final bool isHot;

  const MovieModel({
    required this.movieId,
    required this.title,
    required this.category,
    required this.rating,
    required this.quality,
    this.posterUrl,
    this.description,
    this.isHot = true,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) => MovieModel(
        movieId: (json['movieId'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        quality: json['quality'] as String? ?? '4K Netflix',
        posterUrl: json['posterUrl'] as String?,
        description: json['description'] as String?,
        isHot: json['isHot'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        if (movieId > 0) 'movieId': movieId,
        'title': title,
        'category': category,
        'rating': rating,
        'quality': quality,
        if (posterUrl != null) 'posterUrl': posterUrl,
        if (description != null) 'description': description,
        'isHot': isHot,
      };
}
