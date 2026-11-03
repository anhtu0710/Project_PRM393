// lib/config/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/request_reset_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/customer/room/room_list_screen.dart';
import '../screens/customer/room/room_detail_screen.dart';
import '../screens/customer/saved/saved_screen.dart';
import '../screens/customer/booking/booking_screen.dart';
import '../screens/customer/booking/booking_history_screen.dart';
import '../screens/customer/booking/booking_detail_screen.dart';
import '../screens/customer/review/review_screen.dart';
import '../screens/customer/voucher/voucher_list_screen.dart';
import '../screens/customer/food/food_menu_screen.dart';
import '../screens/customer/movie/movie_list_screen.dart';
import '../screens/customer/profile/customer_profile_screen.dart';
import '../screens/notification/notification_screen.dart';
import '../screens/admin/admin_user_screen.dart';
import '../screens/staff/staff_home_screen.dart';
import '../screens/staff/staff_booking_screen.dart';
import '../screens/staff/staff_room_map_screen.dart';
import '../screens/staff/staff_price_screen.dart';
import '../screens/staff/staff_voucher_screen.dart';
import '../screens/staff/staff_hotel_screen.dart';
import '../screens/staff/staff_profile_screen.dart';
import '../providers/room_provider.dart';
import '../models/room_model.dart';
import '../models/review_eligible_booking_model.dart';

// ── Listenable bridge: Riverpod → GoRouter ────────────────────────────────────
class _AuthNotifierListenable extends ChangeNotifier {
  _AuthNotifierListenable(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
  AuthState get authState => _ref.read(authProvider);
}

// ── Router provider ───────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifierListenable(ref);

  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isResetWithToken =
          state.matchedLocation.startsWith('/reset-password') &&
              (state.uri.queryParameters['token']?.isNotEmpty ?? false);
      if (isResetWithToken) return null;

      final authState = notifier.authState;
      if (!authState.isInitialized) return null;

      final isLoggedIn = authState.isLoggedIn;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/request-reset') ||
          state.matchedLocation.startsWith('/reset-password');

      final loc = state.matchedLocation;
      final isPublicRoute = loc == '/home' ||
          loc == '/saved' ||
          loc == '/rooms' ||
          loc == '/vouchers' ||
          loc == '/food-menu' ||
          loc == '/movies' ||
          (loc.startsWith('/rooms/') && !loc.endsWith('/booking'));

      if (!isLoggedIn && !isAuthRoute && !isPublicRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return _homeForRole(authState.user?.roleId);

      if (isLoggedIn && loc == '/home') {
        final home = _homeForRole(authState.user?.roleId);
        if (home != '/home') return home;
      }

      return null;
    },
    routes: [
      // ── Auth routes ──────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/request-reset',
        name: 'request-reset',
        builder: (_, __) => const RequestResetScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),

      // ── App routes ────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (_, __) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (_, __) => const AdminUserScreen(),
      ),

      // ── Staff routes ──────────────────────────────────────────────────
      GoRoute(
        path: '/staff',
        builder: (_, __) => const StaffHomeScreen(),
      ),
      GoRoute(
        path: '/staff/bookings',
        builder: (_, __) => const StaffBookingScreen(),
      ),
      GoRoute(
        path: '/staff/room-map',
        builder: (_, __) => const StaffRoomMapScreen(initialTabIndex: 0),
      ),
      GoRoute(
        path: '/staff/rooms',
        builder: (_, __) => const StaffRoomMapScreen(initialTabIndex: 1),
      ),
      GoRoute(
        path: '/staff/prices',
        builder: (_, __) => const StaffPriceScreen(),
      ),
      GoRoute(
        path: '/staff/vouchers',
        builder: (_, __) => const StaffVoucherScreen(),
      ),
      GoRoute(
        path: '/staff/hotels',
        builder: (_, __) => const StaffHotelScreen(),
      ),
      GoRoute(
        path: '/staff/profile',
        builder: (_, __) => const StaffProfileScreen(),
      ),

      // ── System Vouchers, Food Menu, Movies ────────────────────────────
      GoRoute(
        path: '/vouchers',
        name: 'vouchers',
        builder: (_, __) => const VoucherListScreen(),
      ),
      GoRoute(
        path: '/food-menu',
        name: 'food-menu',
        builder: (_, __) => const FoodMenuScreen(),
      ),
      GoRoute(
        path: '/movies',
        name: 'movies',
        builder: (_, __) => const MovieListScreen(),
      ),

      // ── Lịch sử, đánh giá, thông báo của khách ────────────────────────
      GoRoute(
        path: '/bookings',
        builder: (_, __) => const BookingHistoryScreen(),
      ),
      GoRoute(
        path: '/bookings/:id',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return BookingDetailScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/bookings/:id/review',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ReviewBookingLoader(bookingId: id);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) => const CustomerProfileScreen(),
      ),

      // ── Saved routes ─────────────────────────────────────────────────
      GoRoute(
        path: '/saved',
        name: 'saved',
        builder: (_, __) => const SavedScreen(),
      ),

      GoRoute(
        path: '/reviews',
        name: 'eligible-reviews',
        builder: (_, __) => const EligibleReviewsScreen(),
      ),
      GoRoute(
        path: '/reviews/:bookingId',
        name: 'create-review',
        builder: (_, state) {
          final booking = state.extra as ReviewEligibleBookingModel?;
          if (booking == null) return const EligibleReviewsScreen();
          return ReviewFormScreen(booking: booking);
        },
      ),

      // ── Room routes ───────────────────────────────────────────────────
      GoRoute(
        path: '/rooms',
        name: 'rooms',
        builder: (_, state) {
          final typeFilter = state.uri.queryParameters['type'];
          return RoomListScreen(typeFilter: typeFilter);
        },
      ),
      GoRoute(
        path: '/rooms/:id',
        name: 'room-detail',
        builder: (_, state) {
          final id = state.pathParameters['id'] ?? '';
          return RoomDetailScreen(roomId: id);
        },
      ),
      GoRoute(
        path: '/rooms/:id/booking',
        name: 'room-booking',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra;
          if (extra != null) {
            return BookingScreen(room: extra as RoomModel);
          }
          return _RoomBookingLoader(roomId: id);
        },
      ),
    ],
  );

  ref.onDispose(notifier.dispose);

  return router;
});

String _homeForRole(String? roleId) {
  if (roleId == null) return '/home';
  switch (roleId.toUpperCase()) {
    case AppConfig.roleAdmin:
      return '/admin';
    case AppConfig.roleStaff:
      return '/staff';
    default:
      return '/home';
  }
}

class _RoomBookingLoader extends ConsumerWidget {
  final String roomId;
  const _RoomBookingLoader({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(roomDetailProvider(roomId));

    if (detailState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (detailState.room == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy phòng')),
      );
    }
    return BookingScreen(room: detailState.room!);
  }
}
