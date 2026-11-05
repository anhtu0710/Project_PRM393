// lib/screens/customer/room/room_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../models/room_model.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/saved_rooms_provider.dart';
import '../../../widgets/app_bottom_nav_bar.dart';
import '../../../widgets/app_image.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _imageController = PageController();

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  String _formatVND(double price) {
    final n = price.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < n.length; i++) {
      if (i > 0 && (n.length - i) % 3 == 0) buf.write('.');
      buf.write(n[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(roomDetailProvider(widget.roomId));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: detailState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            )
          : detailState.error != null
              ? _buildError(detailState.error!)
              : detailState.room == null
                  ? const SizedBox.shrink()
                  : _buildContent(detailState.room!),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (detailState.room != null && !detailState.isLoading)
            _buildBookButton(context, detailState.room!),
          const AppBottomNavBar(currentIndex: 2),
        ],
      ),
    );
  }

  Widget _buildContent(RoomModel room) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildImageCarousel(room)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPriceAndStatus(room),
                const SizedBox(height: 10),
                _buildRoomTitle(room),
                if (room.description != null && room.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    room.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGray,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildPriceOptions(room),
                const SizedBox(height: 20),
                _buildAmenities(room),
                const SizedBox(height: 20),
                _buildHotelBranchCard(room),
                const SizedBox(height: 20),
                _buildRatingHeader(room),
                const SizedBox(height: 12),
                if (room.reviews.isEmpty)
                  const Text('Chưa có đánh giá nào cho phòng này.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textGray))
                else
                  ...room.reviews.map(_buildReviewCard),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Image Carousel ────────────────────────────────────────────────────────────
  Widget _buildImageCarousel(RoomModel room) {
    final List<String> images =
        (room.imageUrl != null && room.imageUrl!.isNotEmpty)
            ? [room.imageUrl!]
            : [];
    final int count = images.isEmpty ? 1 : images.length;

    final savedIds = ref.watch(savedRoomsProvider);
    final isSaved = savedIds.contains(room.roomId);

    return SizedBox(
      height: 270,
      child: Stack(
        children: [
          PageView.builder(
            controller: _imageController,
            itemCount: count,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (context, index) {
              if (images.isEmpty) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF0E8FF), Color(0xFFE0D0F8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.bedroom_parent_outlined,
                        size: 64, color: AppTheme.primary),
                  ),
                );
              }
              return AppImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                width: double.infinity,
              );
            },
          ),
          // Top Back button
          Positioned(
            top: 44,
            left: 12,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back,
                    size: 20, color: AppTheme.textPrimary),
              ),
            ),
          ),
          // Top Bookmark button
          Positioned(
            top: 44,
            right: 12,
            child: GestureDetector(
              onTap: () {
                ref.read(savedRoomsProvider.notifier).toggle(room.roomId);
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  size: 20,
                  color: isSaved ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          // Dots indicator
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                count,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentImageIndex ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: i == _currentImageIndex
                        ? AppTheme.primaryGradient
                        : null,
                    color: i == _currentImageIndex
                        ? null
                        : Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Price & status ─────────────────────────────────────────────────────────
  Widget _buildPriceAndStatus(RoomModel room) {
    final isAvailable = room.status?.toLowerCase() == 'trống' ||
        room.status?.toLowerCase() == 'available';
    final price = room.typeRoom?.pricePerHour;
    final priceText = price != null ? '${_formatVND(price)} đ' : 'Liên hệ';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(color: AppTheme.textPrimary),
            children: [
              TextSpan(
                text: priceText,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const TextSpan(
                text: ' / giờ',
                style: TextStyle(fontSize: 14, color: AppTheme.textGray, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isAvailable
                ? AppTheme.success.withOpacity(0.12)
                : AppTheme.error.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAvailable
                  ? AppTheme.success.withOpacity(0.3)
                  : AppTheme.error.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isAvailable ? AppTheme.success : AppTheme.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                room.status ?? 'Trống',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isAvailable ? AppTheme.success : AppTheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Room title ─────────────────────────────────────────────────────────────
  Widget _buildRoomTitle(RoomModel room) {
    final typeName = room.typeRoom?.typeRoom ?? 'Cinema Box';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          room.nameRoom,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            typeName,
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ── Price Options ─────────────────────────────────────────────────────────
  Widget _buildPriceOptions(RoomModel room) {
    if (room.priceOptions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bảng Giá Theo Gói Thuê',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: room.priceOptions.length,
            itemBuilder: (context, index) {
              final option = room.priceOptions[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      option.typeName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatVND(option.price)} đ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Amenities Grid ─────────────────────────────────────────────────────────
  Widget _buildAmenities(RoomModel room) {
    final amenitiesText = room.amenities ?? 'Máy chiếu 4K, Sofa bed, Điều hòa 2 chiều, Netflix 4K, Wifi 5G';
    final items = amenitiesText.split(',').map((e) => e.trim()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiện Nghi Phòng',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((a) {
            IconData iconData = Icons.star_border;
            if (a.toLowerCase().contains('máy chiếu')) iconData = Icons.movie_outlined;
            if (a.toLowerCase().contains('sofa')) iconData = Icons.weekend_outlined;
            if (a.toLowerCase().contains('điều hòa')) iconData = Icons.ac_unit;
            if (a.toLowerCase().contains('netflix')) iconData = Icons.tv_outlined;
            if (a.toLowerCase().contains('pc')) iconData = Icons.computer_outlined;
            if (a.toLowerCase().contains('board')) iconData = Icons.sports_esports_outlined;
            if (a.toLowerCase().contains('wifi')) iconData = Icons.wifi;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                    child: Icon(iconData, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    a,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Hotel Branch Info Card ────────────────────────────────────────────────
  Widget _buildHotelBranchCard(RoomModel room) {
    if (room.hotel == null) return const SizedBox.shrink();
    final h = room.hotel!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (h.city != null && h.city!.isNotEmpty)
                      Text(
                        h.city!,
                        style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textGray),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  h.address,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                ),
              ),
            ],
          ),
          if (h.phone != null && h.phone!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: AppTheme.textGray),
                const SizedBox(width: 4),
                Text(
                  'Hotline: ${h.phone!}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Rating header ──────────────────────────────────────────────────────────
  Widget _buildRatingHeader(RoomModel room) {
    return Row(
      children: [
        Text(
          room.averageRating > 0 ? room.averageRating.toStringAsFixed(1) : '5.0',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.star, color: AppTheme.goldAccent, size: 22),
        const SizedBox(width: 6),
        Text(
          'Đánh giá (${room.reviewCount})',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── Review card ────────────────────────────────────────────────────────────
  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF3E5F5),
                child: ShaderMask(
                  shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                  child: const Icon(Icons.person, size: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _formatReviewDate(review.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textGray),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    color: AppTheme.goldAccent,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (review.comment != null && review.comment!.isNotEmpty)
            Text(review.comment!,
                style: const TextStyle(fontSize: 12, color: AppTheme.textGray, height: 1.3)),
        ],
      ),
    );
  }

  String _formatReviewDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // ── Book button ────────────────────────────────────────────────────────────
  Widget _buildBookButton(BuildContext context, RoomModel room) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              final isAvailable = room.status?.toLowerCase() == 'trống' ||
                  room.status?.toLowerCase() == 'available';
              if (!isAvailable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Phòng đang ${room.status?.toLowerCase() ?? "bận"}, tạm thời khóa đặt phòng!'),
                    backgroundColor: AppTheme.error,
                  ),
                );
                return;
              }
              context.push('/rooms/${room.roomId}/booking', extra: room);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Đặt Phòng Ngay',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Không thể tải thông tin phòng',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref
                .read(roomDetailProvider(widget.roomId).notifier)
                .loadRoom(widget.roomId),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
