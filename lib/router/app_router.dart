import 'package:firebase_auth/firebase_auth.dart';
import 'package:classlift/router/app_routes.dart';
import 'package:classlift/router/transitions.dart';
import 'package:classlift/screens/home_screen.dart';
import 'package:classlift/screens/login/login_screen.dart';
import 'package:classlift/widgets/home/pending_tasks_section.dart';
import 'package:go_router/go_router.dart';
import 'package:classlift/screens/login/moodle_login_screen.dart';

final GoRouter appRouter = GoRouter(
    initialLocation: '/',
    redirect: (_, state) {
      if (state.uri.path == '/' || state.uri.path == '/login') return null;
      return FirebaseAuth.instance.currentUser == null ? '/login' : null;
    },
    routes: [
      GoRoute(
        path: '/login/moodle',
        builder: (context, state) => const MoodleLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.splash,
        redirect: (_, __) => FirebaseAuth.instance.currentUser == null
            ? AppRoutes.login
            : AppRoutes.home,
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
    ]);
