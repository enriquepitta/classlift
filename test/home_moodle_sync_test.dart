import 'dart:convert';

import 'package:classlift/screens/home_screen.dart';
import 'package:classlift/services/moodle_auth_service.dart';
import 'package:classlift/services/moodle_tasks_service.dart';
import 'package:classlift/utils/options_bottom_sheet.dart';
import 'package:classlift/widgets/home/pending_tasks_section.dart';
import 'package:classlift/widgets/navigation_menu.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  List<Map<String, Object?>> evaluationRows = [];

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    evaluationRows = [];
  });

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
          final sql = call.arguments['sql'] as String;
          if (sql.contains('PRAGMA user_version')) {
            return [
              {'user_version': 2}
            ];
          }
          if (sql.contains('FROM subject_evaluations evaluations')) {
            return evaluationRows;
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
      await auth.useAccount(null);
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

  testWidgets(
      'only implemented options are offered and cancel preserves the home route',
      (tester) async {
    await MoodleAuthService.instance.useAccount(null);
    MoodleTasksService.clearCache();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      home: const Scaffold(body: Text('Pantalla anterior')),
    ));
    navigator.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const HomeScreen(),
    ));
    await tester.pumpAndSettle();
    final homeState = tester.state(find.byType(HomeScreen));
    await tester.tap(find.byTooltip('Añadir'));
    await tester.pumpAndSettle();
    expect(find.byType(OptionsBottomSheet), findsNothing);
    expect(find.text('Horarios de la facultad'), findsOneWidget);
    expect(find.text('Importar desde Excel'), findsOneWidget);
    expect(find.text('Agregar manualmente'), findsNothing);
    await tester.tap(find.byTooltip('Cerrar acciones rápidas'));
    await tester.pumpAndSettle();
    expect(find.text('Importar desde Excel'), findsNothing);
    expect(tester.state(find.byType(HomeScreen)), same(homeState));
    expect(find.textContaining('próximamente'), findsNothing);
    expect(navigator.currentState!.canPop(), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('closing schedule recommendation keeps EDUCA visible',
      (tester) async {
    final auth = MoodleAuthService.instance;
    await auth.useAccount(null);
    MoodleTasksService.clearCache();

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Configurá tu horario'), findsOneWidget);
    expect(find.text('EDUCA Moodle'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Cerrar recomendación').first);
    await tester.pumpAndSettle();

    expect(find.text('Configurá tu horario'), findsNothing);
    expect(find.text('EDUCA Moodle'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Horario opens the weekly schedule and Inicio returns home',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await MoodleAuthService.instance.useAccount(null);
    MoodleTasksService.clearCache();

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Horario'));
    await tester.pumpAndSettle();
    expect(find.text('Vista semanal'), findsOneWidget);
    expect(find.text('Todavía no tenés clases en tu horario.'), findsOneWidget);

    await tester.tap(find.text('Agregar clases'));
    await tester.pumpAndSettle();
    expect(find.byType(OptionsBottomSheet), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Vista semanal'), findsNothing);
    expect(find.text('Configurá tu horario'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Más expands the navigation bar and opens its four destinations',
      (tester) async {
    await MoodleAuthService.instance.useAccount(null);
    MoodleTasksService.clearCache();
    final router = GoRouter(initialLocation: '/home', routes: [
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/login/moodle',
        builder: (_, __) => const Scaffold(body: Text('Formulario Moodle')),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    Finder menuLabel(String label) => find.descendant(
          of: find.byType(CustomBottomNavigationBar),
          matching: find.text(label),
        );

    Future<void> openMore() async {
      await tester.tap(find.text('Más'));
      await tester.pumpAndSettle();
      expect(menuLabel('Cerrar menú'), findsOneWidget);
    }

    final homeState = tester.state(find.byType(HomeScreen));
    final addButton = find.byTooltip('Añadir');
    final addPosition = tester.getCenter(addButton);
    final collapsedBar = tester.getRect(find.byType(CustomBottomNavigationBar));
    await openMore();
    final expandedBar = tester.getRect(find.byType(CustomBottomNavigationBar));
    expect(expandedBar.top, lessThan(collapsedBar.top));
    expect(expandedBar.bottom, collapsedBar.bottom);
    expect(tester.getCenter(addButton), addPosition);
    expect(menuLabel('Inicio').hitTestable(), findsOneWidget);
    expect(menuLabel('Horario').hitTestable(), findsOneWidget);
    expect(menuLabel('Tareas').hitTestable(), findsOneWidget);
    await tester.tapAt(const Offset(12, 40));
    await tester.pumpAndSettle();
    expect(menuLabel('Cerrar menú'), findsNothing);
    expect(tester.state(find.byType(HomeScreen)), same(homeState));

    await openMore();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(menuLabel('Cerrar menú'), findsNothing);

    await openMore();
    await tester.tap(addButton);
    await tester.pumpAndSettle();
    expect(menuLabel('Cerrar menú'), findsNothing);
    expect(find.text('Importar desde Excel'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar acciones rápidas'));
    await tester.pumpAndSettle();

    Future<void> openMoreOption(String label) async {
      await openMore();
      await tester.tap(menuLabel(label));
      await tester.pumpAndSettle();
    }

    await openMoreOption('Calculadora FPUNA');
    expect(find.text('Por etapas'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await openMoreOption('Próximas evaluaciones');
    expect(find.text('No hay evaluaciones próximas.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final today = DateUtils.dateOnly(DateTime.now());
    evaluationRows = [
      for (final (subject, daysAway) in [('Álgebra', 2), ('Física', 4)])
        {
          'subject_name': subject,
          'subject_code': subject,
          'career_code': 'TEST',
          'career_name': 'Informática',
          'semester': 1,
          'evaluation_type': 'Parcial',
          'evaluation_date':
              today.add(Duration(days: daysAway)).millisecondsSinceEpoch,
        },
    ];
    await openMoreOption('Próximas evaluaciones');
    expect(find.text('Álgebra'), findsOneWidget);
    expect(find.text('Física'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await openMoreOption('Política de privacidad');
    expect(find.text('Privacidad'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await openMoreOption('Conectar Moodle');
    expect(find.text('Formulario Moodle'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('expanded navigation scrolls on a short screen with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final selected = <HomeMenuItem>[];

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        bottomNavigationBar: CustomBottomNavigationBar(
          selectedItem: HomeMenuItem.home,
          expanded: true,
          moodleConnected: true,
          onItemTapped: selected.add,
          onAddFacultySchedule: () {},
          onImportExcel: () {},
          onAddOpened: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final privacy = find.text('Política de privacidad');
    expect(find.text('Cerrar menú').hitTestable(), findsOneWidget);
    expect(find.text('Cambiar campus Moodle'), findsOneWidget);
    expect(privacy.hitTestable(), findsNothing);
    await tester.scrollUntilVisible(privacy, 80);
    await tester.pumpAndSettle();
    expect(privacy.hitTestable(), findsOneWidget);
    await tester.tap(privacy);
    expect(selected, [HomeMenuItem.privacy]);
    expect(tester.takeException(), isNull);
  });
}
