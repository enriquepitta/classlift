import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:classlift/models/moodle_task.dart';
import 'package:classlift/services/moodle_auth_service.dart';
import 'package:classlift/services/moodle_tasks_service.dart';
import 'package:classlift/widgets/home/pending_tasks_section.dart';

void main() {
  testWidgets('tasks opened directly have a back button to Home',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/tasks',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/tasks',
          builder: (_, __) => const MoodleTasksScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets(
      'overdue tasks have a separate link instead of occupying the carousel',
      (tester) async {
    final overdue = MoodleTask(
        id: 1,
        moduleId: 101,
        courseId: 1,
        courseName: 'Materia',
        title: 'Tarea antigua',
        description: '',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        submissionStatus: 'new',
        statusKnown: true,
        siteUrl: 'https://school.moodledemo.net');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PendingTasksSection(
                future: Future.value(MoodleTasksResult([overdue])),
                onRefresh: () {}))));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsNothing);
    expect(find.text('No tenés próximas entregas.'), findsOneWidget);
    expect(find.textContaining('Estás al día'), findsNothing);
    await tester.tap(find.text('1 vencida'));
    await tester.pumpAndSettle();
    expect(find.text('Tareas vencidas'), findsOneWidget);
    expect(find.text('Tarea antigua'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('1 vencida'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('status badge is aligned with the bottom right of the card',
      (tester) async {
    final now = DateTime(2026, 9, 17, 12);
    final task = MoodleTask(
        id: 1,
        moduleId: 101,
        courseId: 1,
        courseName: 'Materia',
        title: 'Tarea',
        description: '',
        dueDate: now.add(const Duration(days: 2)),
        submissionStatus: 'new',
        statusKnown: true,
        siteUrl: 'https://school.moodledemo.net');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: SizedBox(
                    width: 540,
                    height: 206,
                    child: MoodleTaskCard(task: task, now: now))))));
    final card = tester.getRect(find.byType(MoodleTaskCard));
    final label = tester.getRect(find.text('Pendiente'));
    expect(card.right - label.right, closeTo(25, 1));
    expect(card.bottom - label.bottom, closeTo(21, 1));
  });
  final tasks = List.generate(
      4,
      (index) => MoodleTask(
            id: index,
            moduleId: index + 100,
            courseId: index,
            courseName: index == 0 ? 'Matemática I' : 'Informática II',
            title: index == 0
                ? 'Ejercitario — Integrales'
                : 'Trabajo práctico — Unidad 3',
            description: index == 0
                ? 'Resolver los ejercicios de la unidad 2 y 3.'
                : 'Entrega del TP con los ejercicios resueltos.',
            dueDate: DateTime.now().add(Duration(hours: index == 0 ? 6 : 30)),
            submissionStatus: 'new',
            statusKnown: true,
            siteUrl: 'https://school.moodledemo.net',
          ));

  testWidgets(
      'carousel fits narrow screens and large text, and opens all tasks',
      (tester) async {
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());
    tester.view.devicePixelRatio = 1;
    for (final width in [320.0, 390.0, 850.0]) {
      for (final scale in [1.0, 2.0]) {
        tester.view.physicalSize = Size(width, 1000);
        await tester.pumpWidget(MaterialApp(
            home: MediaQuery(
          data: MediaQueryData(
              size: Size(width, 1000), textScaler: TextScaler.linear(scale)),
          child: Scaffold(
              body: SingleChildScrollView(
                  child: PendingTasksSection(
                      future: Future.value(MoodleTasksResult(tasks)),
                      onRefresh: () {}))),
        )));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'width=$width scale=$scale');
      }
    }
    await tester.tap(find.text('Ver todas'));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows errors separately from no pending tasks', (tester) async {
    final completer = Completer<MoodleTasksResult>();
    final retryCompleter = Completer<void>();
    var retries = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PendingTasksSection(
                future: completer.future,
                onRefresh: () {
                  retries++;
                  return retryCompleter.future;
                }))));
    completer.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudieron actualizar tus tareas.'), findsOneWidget);
    expect(find.textContaining('Estás al día'), findsNothing);
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(retries, 1);
    expect(find.text('Actualizando'), findsOneWidget);
    retryCompleter.complete();
    await tester.pumpAndSettle();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PendingTasksSection(
                future: Future.value(const MoodleTasksResult([])),
                onRefresh: () {}))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Estás al día'), findsOneWidget);
  });

  testWidgets('session errors ask to reconnect EDUCA', (tester) async {
    final completer = Completer<MoodleTasksResult>();
    var reconnects = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PendingTasksSection(
                future: completer.future,
                onRefresh: () {},
                onReconnect: () => reconnects++))));
    completer.completeError(const MoodleAuthException(
      'Tu sesión de EDUCA venció.',
      requiresReconnect: true,
    ));
    await tester.pumpAndSettle();
    expect(find.text('Tu sesión de EDUCA venció.'), findsOneWidget);
    expect(find.text('Reconectar EDUCA'), findsOneWidget);
    await tester.tap(find.text('Reconectar EDUCA'));
    await tester.pumpAndSettle();
    expect(reconnects, 1);
  });

  testWidgets('reference preview and swipe navigation', (tester) async {
    tester.view.physicalSize = const Size(850, 340);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());
    final loader = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/Poppins/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Poppins/Poppins-Bold.ttf'));
    await tester.runAsync(loader.load);
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await tester.runAsync(icons.load);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'Poppins'),
        home: RepaintBoundary(
            key: key,
            child: Scaffold(
                backgroundColor: Colors.white,
                body: PendingTasksSection(
                    future: Future.value(MoodleTasksResult(tasks)),
                    onRefresh: () {})))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    const previewPath = String.fromEnvironment('TASKS_PREVIEW');
    if (previewPath.isNotEmpty) {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(previewPath).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.drag(find.byType(PageView), const Offset(-560, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
