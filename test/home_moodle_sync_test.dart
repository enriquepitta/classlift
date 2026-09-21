import 'dart:convert';

import 'package:classlift/screens/home_screen.dart';
import 'package:classlift/services/moodle_auth_service.dart';
import 'package:classlift/services/moodle_tasks_service.dart';
import 'package:classlift/widgets/home/pending_tasks_section.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    databaseFactory = databaseFactorySqflitePlugin;
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    await initializeDateFormatting('es_ES');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.tekartik.sqflite'),
            (call) async {
      switch (call.method) {
        case 'getDatabasesPath':
          return '/test';
        case 'openDatabase':
          return {'id': 1};
        case 'query':
          if ((call.arguments['sql'] as String)
              .contains('PRAGMA user_version')) {
            return [
              {'user_version': 2}
            ];
          }
          return <Map<String, Object?>>[];
        default:
          return null;
      }
    });
  });

  testWidgets('Home replaces EDUCA after syncing without changing the day',
      (tester) async {
    await http.runWithClient(() async {
      final auth = MoodleAuthService.instance;
      auth.signOut();
      MoodleTasksService.clearCache();
      final router = GoRouter(initialLocation: '/home', routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/login/moodle',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async {
                auth.session = const MoodleSession(
                    siteUrl: 'https://school.moodledemo.net',
                    token: 'test',
                    userId: 1,
                    fullName: 'Alumno');
                await MoodleTasksService.loadCurrentSession();
                if (context.mounted) context.go('/home');
              },
              child: const Text('Sincronizar prueba'),
            ),
          ),
        ),
      ]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('EDUCA Moodle'), findsOneWidget);
      final homeState = tester.state(find.byType(HomeScreen));
      router.push('/login/moodle');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sincronizar prueba'));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(HomeScreen)), same(homeState));
      expect(find.text('EDUCA Moodle'), findsNothing);
      expect(find.byType(PendingTasksSection), findsOneWidget);
      expect(find.text('Entrega de prueba'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      auth.signOut();
      MoodleTasksService.clearCache();
    },
        () => MockClient((request) async {
              final function = request.bodyFields['wsfunction'];
              return http.Response(
                  jsonEncode(function == 'mod_assign_get_assignments'
                      ? {
                          'courses': [
                            {
                              'id': 1,
                              'fullname': 'Materia',
                              'assignments': [
                                {
                                  'id': 1,
                                  'cmid': 1,
                                  'name': 'Entrega de prueba',
                                  'intro': '',
                                  'duedate': DateTime.now()
                                          .add(const Duration(days: 2))
                                          .millisecondsSinceEpoch ~/
                                      1000,
                                }
                              ],
                            }
                          ],
                        }
                      : {
                          'lastattempt': {
                            'submission': {'status': 'new'}
                          }
                        }),
                  200);
            }));
  });
}
