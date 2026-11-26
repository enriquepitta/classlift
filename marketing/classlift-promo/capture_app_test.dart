// Production widget captures with isolated, fictional fixtures.
// Run from the ClassLift root: flutter test marketing/classlift-promo/capture_app_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:classlift/screens/home_screen.dart';
import 'package:classlift/services/moodle_auth_service.dart';
import 'package:classlift/services/moodle_tasks_service.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Capture the actual app with demonstration data', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = FontLoader('Poppins');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins/Poppins-$weight.ttf'));
    }
    await font.load();
    final anek = FontLoader('AnekLatin')..addFont(rootBundle.load('assets/fonts/AnekLatin-VariableFont_wdth,wght.ttf'));
    await anek.load();
    final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    // Replace the test engine's square placeholder fallback for unstyled text.
    final fallback = FontLoader('Ahem')..addFont(rootBundle.load('assets/fonts/Poppins/Poppins-Regular.ttf'));
    await fallback.load();
    // ignore: invalid_use_of_visible_for_testing_member
    FlutterSecureStorage.setMockInitialValues({});
    databaseFactory = databaseFactorySqflitePlugin;
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final listener in ['registerIdTokenListener', 'registerAuthStateListener']) {
      messenger.setMockMessageHandler(
        'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.$listener',
        (_) async => const StandardMessageCodec().encodeMessage(['demo-events']),
      );
    }
    messenger.setMockMethodCallHandler(const MethodChannel('demo-events'), (_) async => null);
    await initializeDateFormatting('es_ES');
    final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    final rows = <Map<String, Object?>>[
      for (var i = 0; i < days.length; i++)
        for (var j = 0; j < 2; j++)
          {
            'subject_name': j == 0 ? 'Programación II' : 'Física II',
            'career_name': 'Ingeniería Informática',
            'day_of_week': days[i],
            'start_time': j == 0 ? '17:00' : '19:00',
            'end_time': j == 0 ? '18:40' : '20:40',
            'classroom': j == 0 ? 'Aula 12' : 'Aula 08',
            'professor': null,
          }
    ];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.tekartik.sqflite'), (call) async {
      if (call.method == 'getDatabasesPath') return '/demo';
      if (call.method == 'openDatabase') return {'id': 1};
      if (call.method != 'query') return null;
      final sql = call.arguments['sql'] as String;
      if (sql.contains('PRAGMA user_version')) return [{'user_version': 2}];
      if (sql.contains('class_count')) return [for(final d in days) {'day_of_week': d, 'class_count': 2}];
      if (sql.contains('FROM subject_schedules')) {
        if (sql.contains('schedules.day_of_week = ?')) {
          final day = (call.arguments['arguments'] as List).first;
          return rows.where((r) => r['day_of_week'] == day).toList();
        }
        return rows;
      }
      if (sql.contains('FROM selected_subjects')) {
        return [for(var i=0;i<2;i++) {
          'id': i+1, 'career_code':'INF', 'career_name':'Ingeniería Informática',
          'semester':4, 'subject_name':i==0?'Programación II':'Física II',
          'subject_code':'DEMO$i', 'date_added':DateTime(2026,11,1).millisecondsSinceEpoch,
          'is_active':1,
        }];
      }
      return <Map<String, Object?>>[];
    });
    final boundary = GlobalKey();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final render = boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      InlineSpan restoreFont(InlineSpan span) {
        if (span is! TextSpan) return span;
        return TextSpan(text: span.text,
          style: (span.style ?? const TextStyle()).copyWith(
            fontFamily: span.style?.fontFamily ?? 'Poppins'),
          children: span.children?.map(restoreFont).toList());
      }
      void restoreTestFallback(RenderObject object) {
        if (object is RenderParagraph) object.text = restoreFont(object.text);
        object.visitChildren(restoreTestFallback);
      }
      restoreTestFallback(render);
      await tester.pump();
      await tester.runAsync(() async {
        final img = await render.toImage(pixelRatio: 3);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        final file = File('marketing/classlift-promo/assets/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        img.dispose();
      });
      expect(tester.takeException(), isNull);
    }
    await http.runWithClient(() async {
      final auth = MoodleAuthService.instance;
      await auth.useAccount(null);
      auth.session = const MoodleSession(siteUrl:'https://demo.invalid', token:'fictional', userId:1, fullName:'Alex');
      MoodleTasksService.clearCache();
      await MoodleTasksService.loadCurrentSession();
      await tester.pumpWidget(RepaintBoundary(key: boundary, child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3:true, fontFamily:'Poppins', colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF673AB7))),
        home: const HomeScreen(),
      )));
      await capture('home');
      await tester.tap(find.byTooltip('Expandir calendario'));
      await capture('calendar');
      await tester.tap(find.byTooltip('Contraer calendario'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ver todas'));
      await capture('home-tasks');
      await tester.tap(find.text('Ver todas'));
      await capture('tasks');
      await tester.pumpWidget(const SizedBox());
      auth.signOut();
      MoodleTasksService.clearCache();
    }, () => MockClient((request) async {
      final function = request.bodyFields['wsfunction'];
      final today = DateUtils.dateOnly(DateTime.now());
      return http.Response(jsonEncode(function == 'mod_assign_get_assignments'
        ? {'courses': [for(var i=0;i<2;i++) {
          'id':i+1, 'fullname':i==0?'Programación II':'Física II',
          'assignments':[{'id':i+1, 'cmid':i+1, 'name':i==0?'Trabajo práctico 3':'Informe de laboratorio',
            'intro':'', 'duedate':today.add(Duration(days:i+1,hours:23,minutes:59)).millisecondsSinceEpoch ~/1000}]
        }]}
        : {'lastattempt':{'submission':{'status':'new'}}}), 200);
    }));
  });
}
