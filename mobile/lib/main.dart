// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/app_theme.dart';
import 'config/router.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Giới hạn image cache tránh tràn bộ nhớ WebGL/Heap gây đen màn hình (Context Loss) trên Flutter Web
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50 MB

  runApp(
    const ProviderScope(
      child: GenzCinemaApp(),
    ),
  );
}

class GenzCinemaApp extends ConsumerWidget {
  const GenzCinemaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authProvider, (previous, next) {
      if (next.user != null) {
        ref.read(notificationListProvider.notifier).loadNotifications(next.user!.userId);
      } else {
        ref.read(notificationListProvider.notifier).clear();
      }
    });

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'GenzCinema Hotel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
