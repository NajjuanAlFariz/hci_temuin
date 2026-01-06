import 'package:go_router/go_router.dart';

import '../features/splash/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/home/home_screen.dart';
import '../features/report/report_found_screen.dart';
import '../features/report/report_lost_screen.dart';
import '../features/category/category_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/notification/notification_screen.dart';
import '../features/chat/chat_home_screen.dart';
import '../features/chat/chat_detail_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final oobCode = state.uri.queryParameters['oobCode'];
          if (oobCode == null || oobCode.isEmpty) {
            return const LoginScreen();
          }
          return ResetPasswordScreen(oobCode: oobCode);
        },
      ),

      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),

      GoRoute(
        path: '/report-lost',
        builder: (context, state) => const ReportLostScreen(),
      ),
      GoRoute(
        path: '/report-found',
        builder: (context, state) => const ReportFoundScreen(),
      ),

      GoRoute(
        path: '/kategori',
        builder: (context, state) => const CategoryScreen(),
      ),

      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      GoRoute(
        path: '/notification',
        builder: (context, state) => const NotificationScreen(),
      ),

      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatHomeScreen(),
      ),

      GoRoute(
        path: '/chat/detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          return ChatDetailScreen(
            chatId: extra['chatId'],
            partnerName: extra['partnerName'],
          );
        },
      ),
    ],
  );
}
