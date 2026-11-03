// lib/screens/home/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../models/food_menu_model.dart';
import '../../models/movie_model.dart';
import '../../models/room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../providers/movie_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const int _kInfiniteMultiplier = 10000;
  late final PageController _bannerController;
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  String? _selectedHotelId;

  final List<String> banners = [
    'assets/images/Banner_01.png',
    'assets/images/Banner_combo_day.PNG',
    'assets/images/Banner_combo_night.PNG',
    'assets/images/Banner_combo_2h.PNG',
    'assets/images/Banner_combo_4h.PNG',
  ];

  @override
  void initState() {
    super.initState();
    final int totalItems = banners.length * _kInfiniteMultiplier;
    final int initialPage = (totalItems ~/ 2) - ((totalItems ~/ 2) % banners.length);
    _bannerController = PageController(initialPage: initialPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(notificationListProvider.notifier).loadNotifications(user.userId);
      }
    });

    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _bannerController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _showBranchSelector(List<HotelModel> hotels) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chọn Cơ Sở / Chi Nhánh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: ShaderMask(
                shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                child: const Icon(Icons.location_city, color: Colors.white),
              ),
              title: const Text('Tất cả chi nhánh', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: _selectedHotelId == null
                  ? const Icon(Icons.check_circle, color: AppTheme.primary)
                  : null,
              onTap: () {
                setState(() => _selectedHotelId = null);
                ref.read(roomListProvider.notifier).loadRooms();
                Navigator.pop(ctx);
              },
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: hotels.length,
                itemBuilder: (_, index) {
                  final h = hotels[index];
                  final isSelected = h.hotelId == _selectedHotelId;
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: AppTheme.primary),
                    title: Text(h.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(h.address, style: const TextStyle(fontSize: 12, color: AppTheme.textGray), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppTheme.primary)
                        : null,
                    onTap: () {
                      setState(() => _selectedHotelId = h.hotelId);
                      ref.read(roomListProvider.notifier).loadRooms(hotelId: h.hotelId);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotelState = ref.watch(hotelListProvider);
    final roomState = ref.watch(roomListProvider);
    final foodState = ref.watch(foodMenuListProvider);
    final movieState = ref.watch(movieListProvider);

    final selectedHotel = hotelState.hotels.firstWhere(
      (h) => h.hotelId == _selectedHotelId,
      orElse: () => const HotelModel(hotelId: '', name: 'Tất cả cơ sở', address: ''),
    );

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildHeader(context, selectedHotel.name, hotelState.hotels),
              const SizedBox(height: 16),
              _buildHeroBanner(),
              const SizedBox(height: 16),
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // ── Phim Hot GenZ Cinema Đề Cử (Dữ liệu ĐỘNG 100% từ Database) ──────────
              _buildSectionHeader('Phim Hot Đề Cử 4K', context, onViewMore: () => context.push('/movies')),
              const SizedBox(height: 12),
              _buildHotMoviesSection(movieState),
              const SizedBox(height: 24),

              // ── Không Gian Box Chủ Đề (Dữ liệu ĐỘNG 100% từ Database) ──────────────
              _buildSectionHeader('Không Gian Box Chủ Đề', context, onViewMore: () => context.push('/rooms')),
              const SizedBox(height: 12),
              _buildDynamicThemedRooms(roomState),
              const SizedBox(height: 24),

              // ── Thực Đơn Đồ Ăn & Thức Uống (Dữ liệu ĐỘNG 100% từ Database) ──────────
              _buildSectionHeader('Menu Đồ Ăn & Thức Uống F&B', context, onViewMore: () => context.push('/food-menu')),
              const SizedBox(height: 12),
              _buildDynamicFoodMenu(foodState),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  // ── Header với selector Chi nhánh động ────────────────────────────────────
  Widget _buildHeader(BuildContext context, String currentBranchName, List<HotelModel> hotels) {
    return Row(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 38,
          errorBuilder: (_, __, ___) => const Text(
            'GenZ Cinema',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => _showBranchSelector(hotels),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                    child: const Icon(Icons.location_on, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      currentBranchName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textGray),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: const Icon(Icons.notifications_none, size: 26, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  // ── Hero Banner Carousel ───────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Column(
      children: [
        SizedBox(
          height: 165,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (i) => setState(() => _currentBannerIndex = i % banners.length),
            itemBuilder: (context, index) {
              final realIndex = index % banners.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.asset(
                  banners[realIndex],
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentBannerIndex ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                gradient: i == _currentBannerIndex ? AppTheme.primaryGradient : null,
                color: i == _currentBannerIndex ? null : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    final items = [
      {'icon': Icons.confirmation_number_outlined, 'label': 'Voucher', 'route': '/vouchers'},
      {'icon': Icons.history, 'label': 'Lịch sử', 'route': '/bookings'},
      {'icon': Icons.restaurant_menu_outlined, 'label': 'Menu F&B', 'route': '/food-menu'},
      {'icon': Icons.rate_review_outlined, 'label': 'Đánh giá', 'route': '/reviews'},
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                final route = item['route'] as String?;
                if (route != null) {
                  context.push(route);
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item['icon'] as IconData, color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context, {VoidCallback? onViewMore}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        if (onViewMore != null)
          GestureDetector(
            onTap: onViewMore,
            child: const Row(
              children: [
                Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios, size: 10, color: AppTheme.primary),
              ],
            ),
          ),
      ],
    );
  }

  // ── Phim Hot Đề Cử 4K (Dữ liệu ĐỘNG 100% từ Database) ─────────────────────
  Widget _buildHotMoviesSection(MovieListState movieState) {
    if (movieState.isLoading) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      );
    }

    if (movieState.movies.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: movieState.movies.length,
        itemBuilder: (context, index) {
          final movie = movieState.movies[index];
          return GestureDetector(
            onTap: () => context.push('/movies'),
            child: Container(
              width: 230,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
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
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                    child: movie.posterUrl != null && movie.posterUrl!.isNotEmpty
                        ? Image.network(
                            movie.posterUrl!,
                            width: 90,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _posterPlaceholder(),
                          )
                        : _posterPlaceholder(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
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
                          const SizedBox(height: 6),
                          Text(
                            movie.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            movie.category,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textGray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: AppTheme.goldAccent),
                              const SizedBox(width: 4),
                              Text(
                                movie.rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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
        },
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      width: 90,
      height: double.infinity,
      color: const Color(0xFFF3E8FF),
      child: const Icon(Icons.movie_filter_outlined, color: AppTheme.primary, size: 32),
    );
  }

  // ── Không Gian Box Chủ Đề (100% Dynamic từ Database & Lọc theo Chi nhánh) ──
  Widget _buildDynamicThemedRooms(RoomListState roomState) {
    if (roomState.isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      );
    }

    final displayRooms = _selectedHotelId == null
        ? roomState.rooms
        : roomState.rooms.where((r) => r.hotel?.hotelId == _selectedHotelId).toList();

    if (roomState.error != null || displayRooms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: const Center(
          child: Text(
            'Không có dữ liệu phòng thuộc chi nhánh này',
            style: TextStyle(color: AppTheme.textGray),
          ),
        ),
      );
    }

    return SizedBox(
      height: 225,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: displayRooms.length,
        itemBuilder: (context, index) {
          final room = displayRooms[index];
          final typeName = room.typeRoom?.typeRoom ?? 'Cinema Box';
          final price = room.typeRoom?.pricePerHour;
          final priceText = price != null ? '${(price / 1000).toStringAsFixed(0)}k/h' : '';

          return GestureDetector(
            onTap: () => context.push('/rooms/${room.roomId}'),
            child: Container(
              width: 170,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 105,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        room.imageUrl != null && room.imageUrl!.isNotEmpty
                            ? Image.network(
                                room.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                              )
                            : _buildImagePlaceholder(),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  room.status ?? 'Trống',
                                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.nameRoom,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          typeName,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textGray),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShaderMask(
                              shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                              child: Text(
                                priceText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 12, color: AppTheme.goldAccent),
                                const SizedBox(width: 2),
                                Text(
                                  room.averageRating > 0 ? room.averageRating.toStringAsFixed(1) : '5.0',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3E8FF), Color(0xFFE0D0F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.bedroom_parent_outlined, size: 36, color: AppTheme.primary),
      ),
    );
  }

  // ── Menu Đồ Ăn F&B (100% Dynamic từ Database) ──────────────────────────────
  Widget _buildDynamicFoodMenu(FoodMenuState foodState) {
    if (foodState.isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      );
    }

    if (foodState.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: foodState.items.length,
        itemBuilder: (context, index) {
          final food = foodState.items[index];
          final priceText = '${(food.price / 1000).toStringAsFixed(0)}k';

          return GestureDetector(
            onTap: () => context.push('/food-menu'),
            child: Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                        ? Image.network(
                            food.imageUrl!,
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _foodIconPlaceholder(),
                          )
                        : _foodIconPlaceholder(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          food.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          food.category,
                          style: const TextStyle(fontSize: 10, color: AppTheme.textGray),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          priceText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _foodIconPlaceholder() {
    return Container(
      width: 65,
      height: 65,
      color: const Color(0xFFF3E8FF),
      child: const Icon(Icons.fastfood_outlined, color: AppTheme.primary, size: 28),
    );
  }
}
