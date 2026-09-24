// services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/database_models.dart';
import '../models/career.dart';
import '../utils/evaluation_parser.dart';

class DatabaseService {
  static Database? _database;
  static const int _databaseVersion = 2;
  static const String _databaseName = 'classlift.db';

  // Nombres de tablas
  static const String _selectedSubjectsTable = 'selected_subjects';
  static const String _subjectSchedulesTable = 'subject_schedules';
  static const String _subjectGradesTable = 'subject_grades';
  static const String _subjectEvaluationsTable = 'subject_evaluations';
  static const String _appSettingsTable = 'app_settings';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Tabla de materias seleccionadas
    await db.execute('''
      CREATE TABLE $_selectedSubjectsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        career_code TEXT NOT NULL,
        career_name TEXT NOT NULL,
        semester INTEGER NOT NULL,
        subject_name TEXT NOT NULL,
        subject_code TEXT NOT NULL,
        date_added INTEGER NOT NULL,
        last_updated INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        priority INTEGER,
        UNIQUE(career_code, subject_code)
      )
    ''');

    // Tabla de horarios (para futuras extensiones)
    await db.execute('''
      CREATE TABLE $_subjectSchedulesTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_code TEXT NOT NULL,
        career_code TEXT NOT NULL,
        day_of_week TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        classroom TEXT,
        professor TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(subject_code, career_code) REFERENCES $_selectedSubjectsTable(subject_code, career_code)
      )
    ''');

    // Tabla de calificaciones (para futuras extensiones)
    await db.execute('''
      CREATE TABLE $_subjectGradesTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_code TEXT NOT NULL,
        career_code TEXT NOT NULL,
        exam_type TEXT NOT NULL,
        grade REAL,
        max_grade REAL NOT NULL,
        exam_date INTEGER NOT NULL,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(subject_code, career_code) REFERENCES $_selectedSubjectsTable(subject_code, career_code)
      )
    ''');

    await _createSubjectEvaluationsTable(db);

    // Tabla de configuraciones de la app
    await db.execute('''
      CREATE TABLE $_appSettingsTable(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Índices para mejorar el rendimiento
    await db.execute(
        'CREATE INDEX idx_selected_subjects_career ON $_selectedSubjectsTable(career_code, is_active)');
    await db.execute(
        'CREATE INDEX idx_selected_subjects_semester ON $_selectedSubjectsTable(semester, is_active)');
    await db.execute(
        'CREATE INDEX idx_subject_schedules_day ON $_subjectSchedulesTable(day_of_week, is_active)');
    await db.execute(
        'CREATE INDEX idx_subject_evaluations_date ON $_subjectEvaluationsTable(evaluation_date)');
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    await _createAppSettingsTable(db);

    if (oldVersion < 2) {
      await _createSubjectEvaluationsTable(db);
      await db.execute(
          'CREATE INDEX idx_subject_evaluations_date ON $_subjectEvaluationsTable(evaluation_date)');
    }
  }

  static Future<void> _createAppSettingsTable(DatabaseExecutor db) {
    return db.execute('''
      CREATE TABLE IF NOT EXISTS $_appSettingsTable(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _createSubjectEvaluationsTable(DatabaseExecutor db) {
    return db.execute('''
      CREATE TABLE IF NOT EXISTS $_subjectEvaluationsTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_code TEXT NOT NULL,
        career_code TEXT NOT NULL,
        evaluation_type TEXT NOT NULL,
        evaluation_date INTEGER NOT NULL,
        evaluation_time TEXT,
        classroom TEXT,
        professor TEXT,
        FOREIGN KEY(subject_code, career_code) REFERENCES $_selectedSubjectsTable(subject_code, career_code),
        UNIQUE(subject_code, career_code, evaluation_type, evaluation_date, evaluation_time)
      )
    ''');
  }

  static Future<String?> getAppSetting(String key) async {
    final db = await database;
    await _createAppSettingsTable(db);
    final rows = await db.query(
      _appSettingsTable,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  static Future<void> setAppSetting(String key, String value) async {
    final db = await database;
    await _createAppSettingsTable(db);
    await db.insert(
      _appSettingsTable,
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteAppSetting(String key) async {
    final db = await database;
    await _createAppSettingsTable(db);
    await db.delete(
      _appSettingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  // CRUD para Materias Seleccionadas
  static Future<int> insertSelectedSubject(SelectedSubject subject) async {
    final db = await database;
    return await db.insert(
      _selectedSubjectsTable,
      subject.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<SelectedSubject>> getSelectedSubjects({
    String? careerCode,
    int? semester,
    bool activeOnly = true,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (activeOnly) {
      whereClause = 'is_active = ?';
      whereArgs.add(1);
    }

    if (careerCode != null) {
      whereClause +=
          whereClause.isEmpty ? 'career_code = ?' : ' AND career_code = ?';
      whereArgs.add(careerCode);
    }

    if (semester != null) {
      whereClause += whereClause.isEmpty ? 'semester = ?' : ' AND semester = ?';
      whereArgs.add(semester);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _selectedSubjectsTable,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'career_code, semester, priority ASC, subject_name ASC',
    );

    return List.generate(maps.length, (i) => SelectedSubject.fromMap(maps[i]));
  }

  static Future<Map<String, Map<int, List<SelectedSubject>>>>
      getGroupedSelectedSubjects() async {
    final subjects = await getSelectedSubjects();
    Map<String, Map<int, List<SelectedSubject>>> grouped = {};

    for (var subject in subjects) {
      if (!grouped.containsKey(subject.careerCode)) {
        grouped[subject.careerCode] = {};
      }

      if (!grouped[subject.careerCode]!.containsKey(subject.semester)) {
        grouped[subject.careerCode]![subject.semester] = [];
      }

      grouped[subject.careerCode]![subject.semester]!.add(subject);
    }

    return grouped;
  }

  static Future<void> updateSelectedSubject(SelectedSubject subject) async {
    final db = await database;
    await db.update(
      _selectedSubjectsTable,
      subject.copyWith(lastUpdated: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  static Future<void> deleteSelectedSubject(int id) async {
    final db = await database;
    await db.update(
      _selectedSubjectsTable,
      {'is_active': 0, 'last_updated': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> saveSelectedSubjects(
    Map<String, List<String>> subjects,
    List<Career> careers,
    Map<String, Map<int, List<String>>> careerSemesters,
  ) async {
    final db = await database;

    await db.transaction((txn) async {
      // Marcar todas las materias actuales como inactivas
      await txn.update(_selectedSubjectsTable, {
        'is_active': 0,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      });
      await txn.delete(_subjectSchedulesTable);
      await txn.delete(_subjectEvaluationsTable);

      // Insertar/actualizar las nuevas selecciones
      for (var careerEntry in subjects.entries) {
        final careerCode = careerEntry.key;
        final selectedSubjects = careerEntry.value;

        final career = careers.firstWhere(
          (c) => c.code == careerCode,
          orElse: () => Career(careerCode, careerCode),
        );

        for (var subjectName in selectedSubjects) {
          // Encontrar en qué semestre está la materia
          int semester = 1;
          final semesterMap = careerSemesters[careerCode] ?? {};
          for (var semesterEntry in semesterMap.entries) {
            if (semesterEntry.value.contains(subjectName)) {
              semester = semesterEntry.key;
              break;
            }
          }

          // Crear código único para la materia
          final subjectCode =
              '${careerCode}_${semester}_${subjectName.replaceAll(' ', '_').toLowerCase()}';

          // Verificar si ya existe
          final existing = await txn.query(
            _selectedSubjectsTable,
            where: 'career_code = ? AND subject_code = ?',
            whereArgs: [careerCode, subjectCode],
          );

          if (existing.isNotEmpty) {
            // Actualizar existente
            await txn.update(
              _selectedSubjectsTable,
              {
                'is_active': 1,
                'last_updated': DateTime.now().millisecondsSinceEpoch,
                'career_name': career.description,
              },
              where: 'career_code = ? AND subject_code = ?',
              whereArgs: [careerCode, subjectCode],
            );
          } else {
            // Insertar nuevo
            final selectedSubject = SelectedSubject(
              careerCode: careerCode,
              careerName: career.description,
              semester: semester,
              subjectName: subjectName,
              subjectCode: subjectCode,
              dateAdded: DateTime.now(),
            );

            await txn.insert(_selectedSubjectsTable, selectedSubject.toMap());
          }

          final schedules = _extractSchedules(
            subjectName,
            subjectCode: subjectCode,
            careerCode: careerCode,
          );
          for (final schedule in schedules) {
            await txn.insert(_subjectSchedulesTable, schedule.toMap());
          }

          final evaluations = _extractEvaluations(
            subjectName,
            subjectCode: subjectCode,
            careerCode: careerCode,
          );
          for (final evaluation in evaluations) {
            await txn.insert(
              _subjectEvaluationsTable,
              evaluation.toMap(),
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }
      }
    });
  }

  static List<SubjectSchedule> _extractSchedules(
    String selectedSubject, {
    required String subjectCode,
    required String careerCode,
  }) {
    final encodedSchedule =
        selectedSubject.split(' — ').cast<String?>().lastWhere(
              (part) => part != null && part.contains(':'),
              orElse: () => null,
            );

    if (encodedSchedule == null) return [];

    final schedules = <SubjectSchedule>[];
    final timeRangePattern = RegExp(r'^(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})$');

    for (final entry in encodedSchedule.split(';')) {
      final separatorIndex = entry.indexOf(':');
      if (separatorIndex <= 0) continue;

      final day = entry.substring(0, separatorIndex).trim();
      final timeAndClassroom = entry.substring(separatorIndex + 1).split('|');
      final timeMatch =
          timeRangePattern.firstMatch(timeAndClassroom.first.trim());
      if (day.isEmpty || timeMatch == null) continue;

      schedules.add(
        SubjectSchedule(
          subjectCode: subjectCode,
          careerCode: careerCode,
          dayOfWeek: day,
          startTime: timeMatch.group(1)!,
          endTime: timeMatch.group(2)!,
          classroom:
              timeAndClassroom.length > 1 ? timeAndClassroom[1].trim() : null,
        ),
      );
    }

    return schedules;
  }

  static List<SubjectEvaluation> _extractEvaluations(
    String selectedSubject, {
    required String subjectCode,
    required String careerCode,
  }) {
    final encoded = selectedSubject
        .split(' — ')
        .firstWhere((part) => part.startsWith('@eval='), orElse: () => '');
    final evaluations = <SubjectEvaluation>[];
    for (final data in decodeExcelEvaluations(encoded)) {
      final date = DateTime.tryParse(data['date']?.toString() ?? '');
      if (date == null) continue;
      evaluations.add(SubjectEvaluation(
        subjectCode: subjectCode,
        careerCode: careerCode,
        evaluationType: data['type']?.toString() ?? 'Evaluación',
        date: DateTime(date.year, date.month, date.day),
        time: data['time']?.toString(),
        classroom: data['classroom']?.toString(),
        professor: _professorFromSubjectLabel(selectedSubject),
      ));
    }
    return evaluations;
  }

  static String? _professorFromSubjectLabel(String selectedSubject) {
    final parts = selectedSubject.split(' — ');
    if (parts.length < 4) return null;
    final professor = parts[3].trim();
    return professor.isEmpty ? null : professor;
  }

  static Future<List<ScheduledClass>> getClassesForDay(String dayOfWeek) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT
        subjects.subject_name,
        subjects.career_name,
        schedules.day_of_week,
        schedules.start_time,
        schedules.end_time,
        schedules.classroom,
        schedules.professor
      FROM $_subjectSchedulesTable schedules
      INNER JOIN $_selectedSubjectsTable subjects
        ON subjects.subject_code = schedules.subject_code
        AND subjects.career_code = schedules.career_code
      WHERE schedules.day_of_week = ?
        AND schedules.is_active = 1
        AND subjects.is_active = 1
      ORDER BY schedules.start_time ASC, schedules.end_time ASC
    ''', [dayOfWeek]);

    return maps.map(ScheduledClass.fromMap).toList();
  }

  static Future<List<ScheduledClass>> getAllActiveClasses() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT
        subjects.subject_name,
        subjects.career_name,
        schedules.day_of_week,
        schedules.start_time,
        schedules.end_time,
        schedules.classroom,
        schedules.professor
      FROM $_subjectSchedulesTable schedules
      INNER JOIN $_selectedSubjectsTable subjects
        ON subjects.subject_code = schedules.subject_code
        AND subjects.career_code = schedules.career_code
      WHERE schedules.is_active = 1 AND subjects.is_active = 1
      ORDER BY schedules.day_of_week, schedules.start_time ASC
    ''');

    return maps.map(ScheduledClass.fromMap).toList();
  }

  static Future<List<UpcomingEvaluation>> getNextUpcomingEvaluations({
    DateTime? from,
  }) async {
    final db = await database;
    final reference = from ?? DateTime.now();
    final startOfDay = DateTime(reference.year, reference.month, reference.day)
        .millisecondsSinceEpoch;
    final maps = await db.rawQuery('''
      SELECT
        subjects.subject_name,
        subjects.subject_code,
        subjects.career_code,
        subjects.career_name,
        subjects.semester,
        evaluations.evaluation_type,
        evaluations.evaluation_date,
        evaluations.evaluation_time,
        evaluations.classroom,
        evaluations.professor
      FROM $_subjectEvaluationsTable evaluations
      INNER JOIN $_selectedSubjectsTable subjects
        ON subjects.subject_code = evaluations.subject_code
        AND subjects.career_code = evaluations.career_code
      WHERE subjects.is_active = 1 AND evaluations.evaluation_date >= ?
      ORDER BY evaluations.evaluation_date ASC,
        CASE WHEN evaluations.evaluation_time IS NULL THEN 1 ELSE 0 END,
        evaluations.evaluation_time ASC
    ''', [startOfDay]);

    if (maps.isEmpty) return [];
    final firstDate = maps.first['evaluation_date'] as int;
    return maps
        .where((map) => map['evaluation_date'] as int == firstDate)
        .map(UpcomingEvaluation.fromMap)
        .toList();
  }

  static Future<Map<String, int>> getClassesCountByDay() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT schedules.day_of_week, COUNT(*) AS class_count
      FROM $_subjectSchedulesTable schedules
      INNER JOIN $_selectedSubjectsTable subjects
        ON subjects.subject_code = schedules.subject_code
        AND subjects.career_code = schedules.career_code
      WHERE schedules.is_active = 1 AND subjects.is_active = 1
      GROUP BY schedules.day_of_week
    ''');

    return {
      for (final row in rows)
        row['day_of_week'] as String: row['class_count'] as int,
    };
  }

  // Métodos utilitarios
  static Future<int> getTotalSubjectsCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_selectedSubjectsTable WHERE is_active = 1');
    return result.first['count'] as int;
  }

  static Future<Map<String, int>> getSubjectsCountByCareer() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT career_code, career_name, COUNT(*) as count 
      FROM $_selectedSubjectsTable 
      WHERE is_active = 1 
      GROUP BY career_code, career_name
    ''');

    Map<String, int> counts = {};
    for (var row in result) {
      counts[row['career_name'] as String] = row['count'] as int;
    }
    return counts;
  }

  static Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_selectedSubjectsTable);
      await txn.delete(_subjectSchedulesTable);
      await txn.delete(_subjectGradesTable);
      await txn.delete(_subjectEvaluationsTable);
      await txn.delete(_appSettingsTable);
    });
  }

  // Configuraciones de la app
  static Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      _appSettingsTable,
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      _appSettingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );

    return result.isNotEmpty ? result.first['value'] as String : null;
  }

  // Backup y restauración (para futuras funcionalidades)
  static Future<Map<String, dynamic>> exportData() async {
    final subjects = await getSelectedSubjects(activeOnly: false);
    return {
      'version': _databaseVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'subjects': subjects.map((s) => s.toMap()).toList(),
    };
  }
}
