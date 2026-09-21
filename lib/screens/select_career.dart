import 'package:classlift/screens/class_schedule.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:classlift/models/career.dart';
import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/utils/evaluation_parser.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/scheduler.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

class SelectCareerScreen extends StatefulWidget {
  final List<String> availableSheets;
  final String? excelFilePath;

  SelectCareerScreen({required this.availableSheets, this.excelFilePath});

  @override
  _SelectCareerScreenState createState() => _SelectCareerScreenState();
}

class _SelectCareerScreenState extends State<SelectCareerScreen>
    with TickerProviderStateMixin {
  List<String> selectedCareerCodes = [];
  Map<String, Map<int, List<String>>>? careerSemesters;

  bool isLoading = false; // Estado de carga

  Map<int, List<String>>? semestersData;
  int? maxSemester;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _processExcelFile() async {
    final bytes = await File(widget.excelFilePath!).readAsBytes();

    // Normalizá por si hay diferencias de mayúsculas/minúsculas
    final selectedSheets = selectedCareerCodes.map((s) => s.trim()).toList();

    // Procesa SOLO las sheets seleccionadas en un isolate
    final Map<String, Map<int, List<String>>> filtered =
        await compute(parseExcelForSheets, {
      'bytes': bytes,
      'sheets': selectedSheets,
    });

    if (filtered.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SelectSemesterScreen(
            careerSemesters: filtered,
            selectedCareerCodes: selectedCareerCodes,
            careers: careers,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Career> filteredCareers = careers
        .where((career) => widget.availableSheets.contains(career.code))
        .toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          title: const Text(
            "Seleccioná tu carrera",
            style: TextStyle(
              color: ClassliftColors.SecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: ClassliftColors.PrimaryColor,
          iconTheme: IconThemeData(
            color: ClassliftColors.SecondaryColor,
          ),
        ),
      ),
      body: Container(
        color: ClassliftColors.BackgroundColor,
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Text(
                'Seleccionaste ${selectedCareerCodes.length} carrera${selectedCareerCodes.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 16,
                  color: ClassliftColors.Black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredCareers.length,
                itemBuilder: (context, index) {
                  final career = filteredCareers[index];
                  final isSelected = selectedCareerCodes.contains(career.code);

                  return CareerCheckboxTile(
                    index: index,
                    career: career,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedCareerCodes.remove(career.code);
                        } else {
                          selectedCareerCodes.add(career.code);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: ClassliftColors.PrimaryColor,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (selectedCareerCodes.isEmpty) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Por favor, seleccione al menos una carrera')),
                            );
                            return;
                          }

                          setState(() => isLoading = true);

                          Future.microtask(() async {
                            try {
                              await _processExcelFile();
                            } on FormatException catch (error) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error.message)),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => isLoading = false);
                            }
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: ClassliftColors.transparent,
                    foregroundColor: ClassliftColors.White,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: ClassliftColors.White,
                            strokeWidth: 2,
                          ),
                        ),
                      if (!isLoading) const Text('Continuar'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class CareerCheckboxTile extends StatefulWidget {
  final int index;
  final Career career;
  final bool isSelected;
  final VoidCallback onTap;

  CareerCheckboxTile({
    required this.index,
    required this.career,
    required this.isSelected,
    required this.onTap,
  });

  @override
  _CareerCheckboxTileState createState() => _CareerCheckboxTileState();
}

class _CareerCheckboxTileState extends State<CareerCheckboxTile>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(CareerCheckboxTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected != oldWidget.isSelected) {
        if (widget.isSelected) {
          _controller.forward();
        } else {
          _controller.animateBack(0.0,
              duration: const Duration(milliseconds: 500));
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      onTap: widget.onTap,
      backgroundColor: careers.indexOf(widget.career) % 2 == 0
          ? ClassliftColors.White // Color para índices pares
          : ClassliftColors.BackgroundColor, // Color para índices impares
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: SizedBox(
          height: 60,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.career.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    color: ClassliftColors.Black,
                  ),
            ),
          ),
        ),
      ),
      trailing: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Lottie.asset(
            'assets/lottie/checkbox_lottie.json',
            controller: _controller,
            onLoaded: (composition) {
              _controller.duration = composition.duration;
            },
          ),
        ),
      ),
    );
  }
}

Map<String, Map<int, List<String>>> parseExcelForSheets(
    Map<String, Object> args) {
  final bytes = args['bytes'] as Uint8List;
  final wantedSheets =
      (args['sheets'] as List).map((e) => e.toString().trim()).toSet();

  final archive = ZipDecoder().decodeBytes(bytes, verify: false);
  final files = {for (final file in archive.files) file.name: file};
  final workbook = XmlDocument.parse(_readXlsxFile(files, 'xl/workbook.xml'));
  final relationships = XmlDocument.parse(
    _readXlsxFile(files, 'xl/_rels/workbook.xml.rels'),
  );
  final relationshipTargets = {
    for (final relationship in relationships.findAllElements('Relationship'))
      relationship.getAttribute('Id')!: relationship.getAttribute('Target')!,
  };
  final sharedStrings = _readSharedStrings(files);
  const relationshipNamespace =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  final sheetPaths = <String, String>{};

  for (final sheet in workbook.findAllElements('sheet')) {
    final name = sheet.getAttribute('name');
    final relationshipId = sheet.getAttribute(
      'id',
      namespace: relationshipNamespace,
    );
    final target =
        relationshipId == null ? null : relationshipTargets[relationshipId];
    if (name != null && target != null) {
      sheetPaths[name] = 'xl/$target';
    }
  }

  final Map<String, Map<int, List<String>>> data = {};

  for (final sheetName in wantedSheets) {
    final sheetPath = sheetPaths[sheetName];
    if (sheetPath == null || !files.containsKey(sheetPath)) continue;

    // Usamos Set para evitar duplicados, luego convertimos a List ordenada
    final Map<int, Set<String>> semestersMapSet = {};

    final worksheet = XmlDocument.parse(_readXlsxFile(files, sheetPath));
    final rows = worksheet
        .findAllElements('row')
        .map((xmlRow) => _readWorksheetRow(xmlRow, sharedStrings));
    final layout = _detectSheetLayout(rows.take(40).toList());
    if (layout == null) {
      throw FormatException(
        'No se reconocieron las columnas esenciales en la hoja "$sheetName".',
      );
    }

    for (final row in rows) {
      final subject = _valueAt(row, layout.subjectColumn);
      final turnoRaw = _valueAt(row, layout.shiftColumn);
      final sectionRaw = _valueAt(row, layout.sectionColumn);
      final semester = _parseSemester(_valueAt(row, layout.semesterColumn));

      final profesionProfesor = _valueAt(row, layout.titleColumn);
      final profesorApellido = _valueAt(row, layout.lastNameColumn);
      final profesorNombre = _valueAt(row, layout.firstNameColumn);

      // Construir nombre del profesor
      String profesor = _buildProfessorName(
          profesionProfesor, profesorApellido, profesorNombre);

      // Obtener horarios y aulas
      Map<String, String> schedule = _buildSchedule(row, layout);
      final evaluationRow = <int, String>{};
      for (final column in layout.evaluationColumns.entries) {
        evaluationRow[column.key] = row[column.value] ?? '';
      }
      final evaluations = parseExcelEvaluations(evaluationRow);
      final examBoard = parseExamBoard(evaluationRow);

      if (semester == null || semester <= 0 || subject.isEmpty) continue;

      // Parsear turno
      String shift;
      if (turnoRaw.isEmpty) {
        shift = '';
      } else {
        switch (turnoRaw.toUpperCase()) {
          case 'M':
            shift = 'Mañana';
            break;
          case 'T':
            shift = 'Tarde';
            break;
          case 'N':
            shift = 'Noche';
            break;
          default:
            shift = turnoRaw;
            break;
        }
      }

      // Construir label completo
      List<String> parts = [subject, shift];

      if (sectionRaw.isNotEmpty) {
        parts.add(sectionRaw);
      }

      if (profesor.isNotEmpty) {
        parts.add(profesor);
      }

      // Agregar horarios como JSON string
      if (schedule.isNotEmpty) {
        parts.add(_encodeSchedule(schedule));
      }

      // @mesa= va antes de @eval= para que la carga útil de evaluaciones siga
      // siendo el último segmento del label.
      if (examBoard.isNotEmpty) {
        parts.add(encodeExamBoard(examBoard));
      }

      if (evaluations.isNotEmpty) {
        parts.add(encodeExcelEvaluations(evaluations));
      }

      String label = parts.join(' — ');

      final setForSemester =
          semestersMapSet.putIfAbsent(semester, () => <String>{});
      setForSemester.add(label);
    }

    // Convertimos los sets a listas ordenadas
    final Map<int, List<String>> semestersMap = {};
    for (final entry in semestersMapSet.entries) {
      final list = entry.value.toList()..sort();
      semestersMap[entry.key] = list;
    }

    data[sheetName] = semestersMap;
  }

  return data;
}

String _readXlsxFile(Map<String, ArchiveFile> files, String path) {
  final content = files[path]?.content;
  if (content is! List<int>) {
    throw FormatException('No se pudo leer $path del archivo Excel.');
  }
  return utf8.decode(content);
}

List<String> _readSharedStrings(Map<String, ArchiveFile> files) {
  final sharedStringsFile = files['xl/sharedStrings.xml'];
  if (sharedStringsFile == null) return [];

  final document =
      XmlDocument.parse(_readXlsxFile(files, 'xl/sharedStrings.xml'));
  return document.findAllElements('si').map((item) {
    return item.findAllElements('t').map((text) => text.innerText).join();
  }).toList();
}

Map<int, String> _readWorksheetRow(
    XmlElement xmlRow, List<String> sharedStrings) {
  final row = <int, String>{};
  for (final cell in xmlRow.findElements('c')) {
    final reference = cell.getAttribute('r');
    if (reference == null) continue;

    final columnIndex = _columnIndex(reference);
    final valueElements = cell.findElements('v');
    final rawValue = valueElements.isEmpty ? '' : valueElements.first.innerText;
    final cellType = cell.getAttribute('t');
    if (cellType == 's') {
      final sharedStringIndex = int.tryParse(rawValue);
      row[columnIndex] =
          sharedStringIndex == null ? '' : sharedStrings[sharedStringIndex];
    } else if (cellType == 'inlineStr') {
      row[columnIndex] =
          cell.findAllElements('t').map((text) => text.innerText).join();
    } else {
      row[columnIndex] = rawValue;
    }
  }
  return row;
}

int _columnIndex(String cellReference) {
  final letters = RegExp(r'[A-Z]+').firstMatch(cellReference)?.group(0) ?? '';
  var index = 0;
  for (final codeUnit in letters.codeUnits) {
    index = index * 26 + codeUnit - 64;
  }
  return index - 1;
}

int? _parseSemester(dynamic value) {
  if (value is num) {
    if (!value.isFinite || value % 1 != 0) return null;
    return value.toInt();
  }

  final normalizedValue = value?.toString().trim().replaceAll(',', '.') ?? '';
  final parsedValue = num.tryParse(normalizedValue);
  if (parsedValue == null || !parsedValue.isFinite || parsedValue % 1 != 0) {
    return null;
  }

  return parsedValue.toInt();
}

class _ExcelSheetLayout {
  final Map<int, int> evaluationColumns;
  final int subjectColumn;
  final int semesterColumn;
  final int? shiftColumn;
  final int? sectionColumn;
  final int? titleColumn;
  final int? lastNameColumn;
  final int? firstNameColumn;
  final Map<String, _ScheduleColumns> scheduleColumns;

  const _ExcelSheetLayout({
    required this.evaluationColumns,
    required this.subjectColumn,
    required this.semesterColumn,
    this.shiftColumn,
    this.sectionColumn,
    this.titleColumn,
    this.lastNameColumn,
    this.firstNameColumn,
    required this.scheduleColumns,
  });
}

class _ScheduleColumns {
  final int classroomColumn;
  final int timeColumn;

  const _ScheduleColumns(this.classroomColumn, this.timeColumn);
}

_ExcelSheetLayout? _detectSheetLayout(List<Map<int, String>> rows) {
  const days = {
    'lunes': 'Lunes',
    'martes': 'Martes',
    'miercoles': 'Miércoles',
    'jueves': 'Jueves',
    'viernes': 'Viernes',
    'sabado': 'Sábado',
  };
  // Choose the actual column row, not the merged ASIGNATURA group above it.
  final headerRows = rows.where((row) {
    final values = row.values.map(_normalizeHeader).toSet();
    return values.any(['asignatura', 'materia', 'nombreasignatura'].contains) &&
        values.any(['semestre', 'semgrupo', 'semestregrupo', 'nivel', 'grupo']
            .contains);
  }).toList();
  final sample = rows.where((row) => _parseSemester(row[4]) != null).toList();
  final newEvidence = sample.any((row) => (row[13] ?? '').contains('@'));
  final oldEvidence = sample.any((row) => (row[14] ?? '').contains('@'));
  final knownNew = newEvidence && !oldEvidence;
  final knownOld = oldEvidence && !newEvidence;
  final columns = <String, int>{};
  final scheduleColumns = <String, _ScheduleColumns>{};

  for (final row in headerRows) {
    for (final entry in row.entries) {
      final header = _normalizeHeader(entry.value);
      if (header.isEmpty) continue;
      _setFirstColumn(columns, 'subject', entry.key,
          ['asignatura', 'materia', 'nombreasignatura'], header);
      _setFirstColumn(columns, 'semester', entry.key,
          ['semestre', 'semgrupo', 'semestregrupo', 'grupo'], header);
      _setFirstColumn(columns, 'shift', entry.key, ['turno'], header);
      _setFirstColumn(columns, 'section', entry.key, ['seccion'], header);
      _setFirstColumn(columns, 'title', entry.key,
          ['tit', 'titulo', 'titulodocente'], header);
      _setFirstColumn(
          columns, 'lastName', entry.key, ['apellido', 'apellidos'], header);
      _setFirstColumn(
          columns, 'firstName', entry.key, ['nombre', 'nombres'], header);
      _setFirstColumn(columns, 'email', entry.key,
          ['correo', 'correoinstitucional', 'email'], header);

      final day = days[header];
      if (day == null) continue;
      final previousHeader = _normalizeHeader(row[entry.key - 1] ?? '');
      final nextHeader = _normalizeHeader(row[entry.key + 1] ?? '');
      if (previousHeader == 'aula') {
        scheduleColumns[day] = _ScheduleColumns(entry.key - 1, entry.key);
      } else if (nextHeader == 'aula') {
        scheduleColumns[day] = _ScheduleColumns(entry.key + 1, entry.key);
      } else {
        // A grouped day spans a pair on the next header row.
        for (final lower in rows.skip(rows.indexOf(row) + 1).take(2)) {
          final first = _normalizeHeader(lower[entry.key] ?? '');
          final second = _normalizeHeader(lower[entry.key + 1] ?? '');
          if (first == 'aula' && ['hora', 'horario'].contains(second)) {
            scheduleColumns[day] = _ScheduleColumns(entry.key, entry.key + 1);
          } else if (['hora', 'horario'].contains(first) && second == 'aula') {
            scheduleColumns[day] = _ScheduleColumns(entry.key + 1, entry.key);
          }
        }
      }
    }
  }

  // Some sheets place weekday group names above AULA/HORARIO subheaders.
  for (var r = 0; r + 1 < rows.length; r++) {
    for (final entry in rows[r].entries) {
      final day = days[_normalizeHeader(entry.value)];
      if (day == null || scheduleColumns.containsKey(day)) continue;
      final first = _normalizeHeader(rows[r + 1][entry.key] ?? '');
      final second = _normalizeHeader(rows[r + 1][entry.key + 1] ?? '');
      if (['aula', 'salon', 'sala'].contains(first) &&
          ['hora', 'horario', 'horariodeclase'].contains(second)) {
        scheduleColumns[day] = _ScheduleColumns(entry.key, entry.key + 1);
      } else if (['hora', 'horario', 'horariodeclase'].contains(first) &&
          ['aula', 'salon', 'sala'].contains(second)) {
        scheduleColumns[day] = _ScheduleColumns(entry.key + 1, entry.key);
      }
    }
  }
  if (knownNew || knownOld) {
    final offset = knownNew ? 0 : 1;
    columns.putIfAbsent('subject', () => 2);
    columns.putIfAbsent('semester', () => 4);
    columns.putIfAbsent('shift', () => 8);
    columns.putIfAbsent('section', () => 9);
    columns.putIfAbsent('title', () => 10 + offset);
    columns.putIfAbsent('lastName', () => 11 + offset);
    columns.putIfAbsent('firstName', () => 12 + offset);
    for (var i = 0; i < days.length; i++) {
      final start = (knownNew ? 31 : 34) + i * 2;
      scheduleColumns.putIfAbsent(
          days.values.elementAt(i), () => _ScheduleColumns(start, start + 1));
    }
  }
  final subjectColumn = columns['subject'];
  final semesterColumn = columns['semester'];
  if (subjectColumn == null || semesterColumn == null) return null;
  if (scheduleColumns.isEmpty) {
    throw const FormatException(
        'No se reconocieron las parejas día/horario y aula de la hoja.');
  }

  final evaluationColumns = <int, int>{};
  var revision = 0;
  for (final row in rows.take(40)) {
    final groups = row.entries.where((e) {
      final h = _normalizeHeader(e.value);
      return h.contains('parcial') ||
          h.contains('final') ||
          h == 'revision' ||
          h.contains('evaluacionprimeraetapa') ||
          h.contains('evaluacionsegundaetapa');
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final group in groups) {
      final h = _normalizeHeader(group.value);
      int? target;
      if (h.contains('parcial') || h.contains('etapa')) {
        target = h.contains('2') || h.contains('segunda') ? 18 : 15;
      } else if (h.contains('final') && !h.contains('derecho')) {
        target = h.startsWith('2')
            ? 26
            : h.startsWith('1')
                ? 21
                : null;
      } else if (h == 'revision') {
        target = revision++ == 0 ? 24 : 29;
      }
      if (target == null) continue;
      final lowerIndex = rows.indexOf(row) + 1;
      if (lowerIndex >= rows.length) continue;
      final lower = rows[lowerIndex];
      final end = groups
              .where((e) => e.key > group.key)
              .map((e) => e.key)
              .firstOrNull ??
          group.key + 3;
      for (var c = group.key; c < end && c < group.key + 3; c++) {
        final sub = _normalizeHeader(lower[c] ?? '');
        if (['dia', 'fecha'].contains(sub)) evaluationColumns[target] = c;
        if (['hora', 'horario'].contains(sub)) {
          evaluationColumns[target + 1] = c;
        }
        if (sub == 'aula' && target != 24 && target != 29) {
          evaluationColumns[target + 2] = c;
        }
      }
    }
  }
  // La mesa examinadora repite el encabezado "Miembro" dos veces, así que sus
  // columnas se resuelven por posición y no por texto.
  for (var r = 0; r + 1 < rows.length && r < 40; r++) {
    for (final entry in rows[r].entries) {
      if (_normalizeHeader(entry.value) != 'mesaexaminadora') continue;
      final lower = rows[r + 1];
      var member = 32;
      for (var c = entry.key; c < entry.key + 3; c++) {
        final sub = _normalizeHeader(lower[c] ?? '');
        if (sub == 'presidente') {
          evaluationColumns[31] = c;
        } else if (sub == 'miembro' && member <= 33) {
          evaluationColumns[member++] = c;
        }
      }
    }
  }

  if (evaluationColumns.isEmpty && (knownNew || knownOld)) {
    final sources = knownNew
        ? <int, int>{
            15: 14,
            16: 15,
            18: 16,
            19: 17,
            21: 18,
            22: 19,
            23: 20,
            24: 21,
            25: 22,
            26: 23,
            27: 24,
            28: 25,
            29: 26,
            30: 27,
            31: 28,
            32: 29,
            33: 30
          }
        : <int, int>{for (var i = 15; i <= 33; i++) i: i};
    evaluationColumns.addAll(sources);
  }

  return _ExcelSheetLayout(
    evaluationColumns: evaluationColumns,
    subjectColumn: subjectColumn,
    semesterColumn: semesterColumn,
    shiftColumn: columns['shift'],
    sectionColumn: columns['section'],
    titleColumn: columns['title'],
    lastNameColumn: columns['lastName'],
    firstNameColumn: columns['firstName'],
    scheduleColumns: scheduleColumns,
  );
}

void _setFirstColumn(
  Map<String, int> columns,
  String key,
  int value,
  List<String> aliases,
  String header,
) {
  if (!columns.containsKey(key) && aliases.contains(header)) {
    columns[key] = value;
  }
}

String _normalizeHeader(String value) {
  const replacements = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
  };
  var normalized = value.toLowerCase().trim();
  replacements.forEach((source, replacement) {
    normalized = normalized.replaceAll(source, replacement);
  });
  return normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String _valueAt(Map<int, String> row, int? index) =>
    index == null ? '' : (row[index]?.trim() ?? '');

Map<String, String> _buildSchedule(
  Map<int, String> row,
  _ExcelSheetLayout layout,
) {
  final schedule = <String, String>{};
  for (final entry in layout.scheduleColumns.entries) {
    final time = _valueAt(row, entry.value.timeColumn);
    final classroom = _valueAt(row, entry.value.classroomColumn);
    if (_isTimeRange(time) && _isClassroom(classroom)) {
      schedule[entry.key] = '$time|$classroom';
    }
  }

  return schedule;
}

bool _isTimeRange(String value) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})$')
      .firstMatch(value.trim());
  if (match == null) return false;
  final hours = [int.parse(match[1]!), int.parse(match[3]!)];
  final minutes = [int.parse(match[2]!), int.parse(match[4]!)];
  return hours.every((h) => h < 24) &&
      minutes.every((m) => m < 60) &&
      hours[0] * 60 + minutes[0] < hours[1] * 60 + minutes[1];
}

bool _isClassroom(String value) {
  final text = value.trim();
  return text.isNotEmpty && !text.contains(':') && !text.contains('@');
}

// Función para codificar el horario como string
String _encodeSchedule(Map<String, String> schedule) {
  List<String> encodedSchedule = [];
  for (var entry in schedule.entries) {
    encodedSchedule.add('${entry.key}:${entry.value}');
  }
  return encodedSchedule.join(';');
}

// Función para decodificar el horario desde string
Map<String, String> _decodeSchedule(String encodedSchedule) {
  Map<String, String> schedule = {};
  if (encodedSchedule.isEmpty) return schedule;

  final entries = encodedSchedule.split(';');
  for (var entry in entries) {
    final parts = entry.split(':');
    if (parts.length >= 2) {
      final day = parts[0];
      final timeAndRoom =
          parts.sublist(1).join(':'); // En caso de que haya ":" en el horario
      schedule[day] = timeAndRoom;
    }
  }
  return schedule;
}

// Función helper para construir el nombre del profesor
String _buildProfessorName(String profesion, String apellido, String nombre) {
  List<String> nameParts = [];

  if (profesion.isNotEmpty && !profesion.contains('@')) {
    nameParts.add(profesion);
  }

  if (nombre.isNotEmpty && !nombre.contains('@')) {
    final nombres = nombre.split(' ');
    nameParts.add(nombres.first);
  }

  if (apellido.isNotEmpty && !apellido.contains('@')) {
    final apellidos = apellido.split(' ');
    nameParts.add(apellidos.first);
  }

  return nameParts.join(' ');
}
