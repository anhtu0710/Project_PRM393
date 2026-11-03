// lib/screens/customer/movie/movie_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../models/movie_model.dart';
import '../../../providers/movie_provider.dart';
import '../../../widgets/app_bottom_nav_bar.dart';

class MovieListScreen extends ConsumerStatefulWidget {
  const MovieListScreen({super.key});

  @override
  ConsumerState<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends ConsumerState<MovieListScreen> {
  String? _selectedCategory;

  final List<String> _categories = [
    'Tất cả',
    'Kinh Dị',
    'Hành Động',
    'Hài Hước',
    'Hoạt Hình',
    'Kịch Tính',
    'Khoa Học',
  ];

  @override
  Widget build(BuildContext context) {
    final movieState = ref.watch(movieListProvider);

    final filteredMovies = _selectedCategory == null || _selectedCategory == 'Tất cả'
        ? movieState.movies
        : movieState.movies.where((m) => m.category.contains(_selectedCategory!)).toList();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Danh Sách Phim HOT Đề Cử 4K',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = (_selectedCategory == null && cat == 'Tất cả') ||
                      _selectedCategory == cat;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat == 'Tất cả' ? null : cat;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.primaryGradient : null,
                        color: isSelected ? null : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : AppTheme.cardBorder,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Movie List
          Expanded(
            child: movieState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  )
                : filteredMovies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.movie_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('Không tìm thấy phim phù hợp', style: TextStyle(color: AppTheme.textGray)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredMovies.length,
                        itemBuilder: (context, index) {
                          return _buildMovieCard(filteredMovies[index]);
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildMovieCard(MovieModel movie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Poster Image
            SizedBox(
              width: 100,
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  movie.posterUrl != null && movie.posterUrl!.isNotEmpty
                      ? Image.network(
                          movie.posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _posterPlaceholder(),
                        )
                      : _posterPlaceholder(),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        movie.quality,
                        style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      movie.category,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                    ),
                    if (movie.description != null && movie.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        movie.description!,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: AppTheme.goldAccent),
                            const SizedBox(width: 4),
                            Text(
                              movie.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () => context.push('/rooms'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Đặt phòng xem', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      color: const Color(0xFFF3E8FF),
      child: const Center(
        child: Icon(Icons.movie_filter_outlined, color: AppTheme.primary, size: 36),
      ),
    );
  }
}
