import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:classlift/screens/select_career.dart';
import 'package:classlift/utils/evaluation_parser.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List workbook(bool newer,
    {bool headers = true,
    int shift = 0,
    bool grouped = false,
    bool invalid = false}) {
  String col(int i) {
    var s = '';
    for (i++; i > 0; i = (i - 1) ~/ 26) {
      s = String.fromCharCode(65 + (i - 1) % 26) + s;
    }
    return s;
  }

  String row(int n, Map<int, String> values) =>
      '<row r="$n">${values.entries.map((e) => '<c r="${col(e.key + shift)}$n" t="inlineStr"><is><t>${e.value}</t></is></c>').join()}</row>';
  final title = newer ? 10 : 11;
  final start = newer ? 31 : 34;
  final h = <int, String>{
    2: 'Asignatura',
    3: 'Nivel',
    4: 'Sem / Grupo',
    8: 'Turno',
    9: 'SECCIÓN',
    title: 'Tít',
    title + 1: 'Apellido',
    title + 2: 'Nombre',
    title + 3: 'Correo\n Institucional'
  };
  final data = <int, String>{
    2: 'Álgebra',
    3: '---',
    4: '2.0',
    8: 'M',
    9: 'MI',
    title: 'Lic.',
    title + 1: 'Ríos',
    title + 2: 'Ana',
    title + 3: 'ana@example.com'
  };
  final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
  final groups = <int, String>{1: 'ASIGNATURA'};
  final exam = newer ? 14 : 15;
  groups[exam] = 'Evaluación Primera\n Etapa';
  h[exam] = 'Día';
  h[exam + 1] = 'Hora';
  data[exam] = '12/09/2026';
  data[exam + 1] = '08:00';
  for (var i = 0; i < 6; i++) {
    h[start + i * 2] = ' AULA ';
    h[start + i * 2 + 1] = ' ${days[i]}\n';
    data[start + i * 2] = 'F${i + 1}';
    data[start + i * 2 + 1] = '08:00 - 10:00';
    if (grouped) {
      groups[start + i * 2] = days[i];
      h[start + i * 2 + 1] = 'Horario';
    }
  }
  if (invalid) {
    data[start] = 'aula@example.com';
    data[start + 3] = '28:00 - 30:00';
    data[start + 4] = '08:00 - 10:00';
    data[start + 7] = '10:00 - 08:00';
  }
  final archive = Archive();
  void add(String path, String text) {
    final bytes = utf8.encode(text);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  add('xl/workbook.xml',
      '<workbook xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="LCIk" r:id="rId1"/></sheets></workbook>');
  add('xl/_rels/workbook.xml.rels',
      '<Relationships><Relationship Id="rId1" Target="worksheets/sheet1.xml"/></Relationships>');
  add('xl/worksheets/sheet1.xml',
      '<worksheet><sheetData>${headers ? row(10, groups) + row(11, h) : ""}${row(12, data)}</sheetData></worksheet>');
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

void main() {
  for (final newer in [false, true]) {
    for (final headers in [false, true]) {
      test('formato $newer encabezados $headers, docente y seis días', () {
        final result = parseExcelForSheets({
          'bytes': workbook(newer, headers: headers),
          'sheets': ['LCIk']
        });
        final label = result['LCIk']![2]!.single;
        expect(label, contains('Lic. Ana Ríos'));
        expect(label, isNot(contains('@example.com')));
        expect(label, contains('Lunes:08:00 - 10:00|F1'));
        expect(label, contains('Sábado:08:00 - 10:00|F6'));
        expect(decodeExcelEvaluations(label.split(' — ').last).first['date'],
            '2026-09-12');
      });
    }
  }
  test('columnas desplazadas y encabezados normalizados', () {
    final result = parseExcelForSheets({
      'bytes': workbook(true, shift: 3),
      'sheets': ['LCIk']
    });
    expect(result['LCIk']![2]!.single, contains('Miércoles:08:00 - 10:00|F3'));
  });
  for (final newer in [false, true]) {
    test('encabezados agrupados y evaluaciones desplazadas: $newer', () {
      final result = parseExcelForSheets({
        'bytes': workbook(newer, shift: 5, grouped: true),
        'sheets': ['LCIk']
      });
      final label = result['LCIk']![2]!.single;
      expect(label, contains('Lunes:08:00 - 10:00|F1'));
      expect(label, contains('Sábado:08:00 - 10:00|F6'));
      expect(decodeExcelEvaluations(label.split(' — ').last).first['date'],
          '2026-09-12');
    });
    test('fallback descarta horarios y aulas inválidos: $newer', () {
      final result = parseExcelForSheets({
        'bytes': workbook(newer, headers: false, invalid: true),
        'sheets': ['LCIk']
      });
      final label = result['LCIk']![2]!.single;
      for (final day in ['Lunes:', 'Martes:', 'Miércoles:', 'Jueves:']) {
        expect(label, isNot(contains(day)));
      }
      expect(label, contains('Viernes:08:00 - 10:00|F5'));
    });
  }
  test('diagnóstico para columnas esenciales ausentes', () {
    expect(
        () => parseExcelForSheets({
              'bytes': workbook(true, headers: false, shift: 8),
              'sheets': ['LCIk']
            }),
        throwsFormatException);
  });
  const path =
      '/tmp/codex-remote-attachments/01a0a9e9-896b-75d3-90e7-3412fc12eccd/3E794238-D838-40EA-8854-0300AA530A73/1-Planificacion-de-clases-y-examenes-.Segundo-Periodo-Academico-versionweb02082026.Planes-anteriores.xlsx';
  test('libro real segundo período IEL: semestre, horario y evaluaciones', () {
    final result = parseExcelForSheets({
      'bytes': File(path).readAsBytesSync(),
      'sheets': ['IEL']
    });
    final label = result['IEL']![8]!.firstWhere(
        (s) => s.startsWith('Administración y Recursos Humanos — Mañana'));
    expect(label, contains('Lic. Carlos Céspedes'));
    expect(label, contains('Sábado:08:15 - 12:00|I01'));
    expect(label, isNot(contains('@pol.una.py')));
    final exams = decodeExcelEvaluations(label.split(' — ').last);
    expect(exams.first['date'], '2026-09-12');
    expect(exams.first['time'], '08:15');
    expect(exams.any((e) => e['date'] == '2026-12-05'), isTrue);
  }, skip: !File(path).existsSync());
}
