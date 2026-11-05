// lib/utils/image_url.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/app_config.dart';

String resolveImageUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final cleanUrl = url.trim();

  // Android/iOS: tải thẳng trực tiếp, không cần proxy
  if (!kIsWeb) return cleanUrl;

  // Web: ảnh cùng domain backend thì không cần proxy
  final baseNoApi = AppConfig.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
  if (cleanUrl.startsWith(baseNoApi)) return cleanUrl;

  // Web: ảnh domain ngoài thì đi qua proxy
  return '${AppConfig.baseUrl}/proxy-image?url=${Uri.encodeComponent(cleanUrl)}';
}
