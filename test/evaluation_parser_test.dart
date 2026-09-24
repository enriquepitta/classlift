import 'package:classlift/utils/evaluation_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseExcelEvaluationDate', () {
    test('convierte una fecha serial de Excel', () {
      expect(parseExcelEvaluationDate('46127'), DateTime(2026, 4, 15));
    });

    test('convierte texto con día y fecha', () {
      expect(parseExcelEvaluationDate('Mié 15/04/26'), DateTime(2026, 4, 15));
    });
  });

  group('parseExcelEvaluations', () {
    test('extrae parciales, finales y revisiones disponibles', () {
      final evaluations = parseExcelEvaluations({
        15: '46127',
        16: '08:00',
        17: 'Lab HPC',
        18: '46176',
        19: '0.3333333',
        20: 'E02',
        24: '46207',
        25: '10:30',
      });

      expect(evaluations, hasLength(3));
      expect(evaluations[0].type, '1.er Parcial');
      expect(evaluations[0].date, DateTime(2026, 4, 15));
      expect(evaluations[0].time, '08:00');
      expect(evaluations[0].classroom, 'Lab HPC');
      expect(evaluations[1].time, '08:00');
      expect(evaluations[2].type, 'Revisión');
      expect(evaluations[2].classroom, isNull);
    });

    test('codifica y decodifica los datos sin perder campos', () {
      final encoded = encodeExcelEvaluations([
        ParsedExcelEvaluation(
          type: '1.er Final',
          date: DateTime(2026, 6, 24),
          time: '08:00',
          classroom: 'Lab HPC',
        ),
      ]);

      final decoded = decodeExcelEvaluations(encoded);
      expect(decoded.single['type'], '1.er Final');
      expect(decoded.single['date'], '2026-06-24');
      expect(decoded.single['time'], '08:00');
      expect(decoded.single['classroom'], 'Lab HPC');
    });
  });
}
