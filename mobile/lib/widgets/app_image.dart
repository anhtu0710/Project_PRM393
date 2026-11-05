import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_config.dart';

class AppImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  String _resolveImageUrl(String rawUrl) {
    if (rawUrl.isEmpty) return '';
    
    if (rawUrl.startsWith('/api/')) {
      final base = AppConfig.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
      return '$base$rawUrl';
    }

    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      final encoded = Uri.encodeComponent(rawUrl);
      return '${AppConfig.baseUrl}/proxy-image?url=$encoded';
    }

    return rawUrl;
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.purple.shade50,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.purple.shade50,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_filter_rounded, size: 28, color: Color(0xFF9462FF)),
          SizedBox(height: 4),
          Text('GenZ Cinema', style: TextStyle(fontSize: 10, color: Color(0xFF9462FF), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = (imageUrl ?? '').trim();
    if (cleanUrl.isEmpty) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: errorWidget ?? _defaultErrorWidget(),
      );
    }

    final resolved = _resolveImageUrl(cleanUrl);

    // Tính toán memCacheWidth an toàn (tránh lỗi Infinity.toInt())
    int? cacheWidth;
    if (width != null && width!.isFinite && width! > 0) {
      cacheWidth = (width! * 2).toInt();
    } else {
      cacheWidth = 800; // Mức mã hóa ảnh đệm mặc định an toàn cho RAM
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: resolved,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      placeholder: (context, url) => placeholder ?? _defaultPlaceholder(),
      errorWidget: (context, url, error) {
        return errorWidget ?? _defaultErrorWidget();
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
