import 'package:classlift/router/transitions.dart';
import 'package:classlift/screens/forgot_password_screen.dart';
import 'package:classlift/screens/home_screen.dart';
import 'package:classlift/screens/login/login_screen.dart';
import 'package:classlift/screens/splash_screen.dart';
import 'package:classlift/widgets/home/pending_tasks_section.dart';
import 'package:go_router/go_router.dart';
import 'package:classlift/screens/login/moodle_login_screen.dart';

final GoRouter appRouter = GoRouter(initialLocation: '/', routes: [
  GoRoute(
    path: '/login/moodle',
    builder: (context, state) => const MoodleLoginScreen(),
  ),
  GoRoute(
    path: '/',
    pageBuilder: (context, state) => buildFadeTransition(
      key: state.pageKey,
      child: const SplashScreen(),
    ),
  ),
  GoRoute(
    path: '/login',
    pageBuilder: (context, state) => buildFadeTransition(
      key: state.pageKey,
      child: const LoginScreen(),
    ),
  ),
  GoRoute(
    path: '/home',
    builder: (context, state) => const HomeScreen(),
  ),
  GoRoute(
    path: '/tasks',
    builder: (context, state) => const MoodleTasksScreen(),
  ),
  GoRoute(
    path: '/forgot-password',
    pageBuilder: (context, state) => buildIOSPageTransition(
      key: state.pageKey,
      child: const ForgotPasswordScreen(),
    ),
  ),
]);
