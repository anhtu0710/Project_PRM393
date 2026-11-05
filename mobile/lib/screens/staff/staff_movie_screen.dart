// lib/screens/staff/staff_movie_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../models/movie_model.dart';
import '../../providers/movie_provider.dart';
import '../../widgets/app_image.dart';

class StaffMovieScreen extends ConsumerStatefulWidget {
  const StaffMovieScreen({super.key});

  @override
  ConsumerState<StaffMovieScreen> createState() => _StaffMovieScreenState();
}

class _StaffMovieScreenState extends ConsumerState<StaffMovieScreen> {
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF4B5563)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movieState = ref.watch(movieListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Phim Hot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(movieListProvider.notifier).loadMovies(),
          ),
        ],
      ),
      body: movieState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : movieState.movies.isEmpty
              ? const Center(child: Text('Chưa có phim nào'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: movieState.movies.length,
                  itemBuilder: (context, index) {
                    final movie = movieState.movies[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            AppImage(
                              imageUrl: movie.posterUrl,
                              width: 60,
                              height: 80,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movie.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Thể loại: ${movie.category} • ${movie.quality}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 14, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(
                                        movie.rating.toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showMovieDialog(movie),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(movie.movieId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMovieDialog(null),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showMovieDialog(MovieModel? movie) {
    final isEdit = movie != null;
    final titleController = TextEditingController(text: movie?.title ?? '');
    final ratingController = TextEditingController(text: movie != null ? movie.rating.toString() : '');
    final qualityController = TextEditingController(text: movie?.quality ?? '');
    final posterController = TextEditingController(text: movie?.posterUrl ?? '');
    final descController = TextEditingController(text: movie?.description ?? '');

    final List<String> presetCategories = ['Hành Động', 'Kinh Dị', 'Hài Hước', 'Hoạt Hình', 'Khoa Học', 'Kịch Tính'];
    String currentCat = movie?.category ?? '';
    bool isCustom = currentCat.isNotEmpty && !presetCategories.contains(currentCat);
    String selectedCategory = isCustom ? 'Khác...' : (presetCategories.contains(currentCat) ? currentCat : presetCategories.first);
    final customCategoryController = TextEditingController(text: isCustom ? currentCat : '');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? 'Sửa thông tin phim' : 'Thêm phim mới'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Tên phim'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'VD: Avatar: The Way of Water',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFieldLabel('Thể loại'),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: [
                      ...presetCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                      const DropdownMenuItem(value: 'Khác...', child: Text('Khác (Tự nhập)...')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedCategory = val;
                        });
                      }
                    },
                  ),
                  if (selectedCategory == 'Khác...') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: customCategoryController,
                      decoration: InputDecoration(
                        hintText: 'Nhập thể loại khác...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildFieldLabel('Điểm đánh giá'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: ratingController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'VD: 4.9',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFieldLabel('Chất lượng'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: qualityController,
                    decoration: InputDecoration(
                      hintText: 'VD: 4K Netflix, 4K Full HD...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFieldLabel('URL Poster Phim'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: posterController,
                    decoration: InputDecoration(
                      hintText: 'VD: https://...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFieldLabel('Mô tả'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Nhập nội dung tóm tắt phim...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () async {
                final title = titleController.text.trim();
                final finalCategory = selectedCategory == 'Khác...'
                    ? customCategoryController.text.trim()
                    : selectedCategory;
                final rating = double.tryParse(ratingController.text.trim()) ?? 5.0;

                if (title.isEmpty || finalCategory.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên phim và chọn thể loại')),
                  );
                  return;
                }

                final newMovie = MovieModel(
                  movieId: isEdit ? movie.movieId : 0,
                  title: title,
                  category: finalCategory,
                  rating: rating > 0 ? rating : 5.0,
                  quality: qualityController.text.trim().isNotEmpty ? qualityController.text.trim() : '4K Netflix',
                  posterUrl: posterController.text.trim().isNotEmpty ? posterController.text.trim() : null,
                  description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                  isHot: true,
                );

                final notifier = ref.read(movieListProvider.notifier);
                final success = isEdit
                    ? await notifier.updateMovie(movie.movieId, newMovie)
                    : await notifier.createMovie(newMovie);

                if (mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Thành công' : 'Thất bại')),
                  );
                }
              },
              child: Text(isEdit ? 'Lưu' : 'Tạo mới', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa phim này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await ref.read(movieListProvider.notifier).deleteMovie(id);
              if (mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Đã xóa phim' : 'Xóa thất bại')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
