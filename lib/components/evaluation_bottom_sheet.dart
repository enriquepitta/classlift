import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/database_models.dart';
import '../utils/evaluation_parser.dart';
import '../utils/subject_label.dart';

Future<void> showEvaluationBottomSheet(
  BuildContext context,
  UpcomingEvaluation evaluation,
  Color subjectColor,
  Color accentColor,
) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFAFAFF),
      barrierColor: const Color(0xFF141B46).withValues(alpha: 0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => EvaluationBottomSheet(
        evaluation: evaluation,
        subjectColor: subjectColor,
        accentColor: accentColor,
      ),
    );

class EvaluationBottomSheet extends StatelessWidget {
  final UpcomingEvaluation evaluation;
  final Color subjectColor;
  final Color accentColor;

  const EvaluationBottomSheet({
    super.key,
    required this.evaluation,
    required this.subjectColor,
    required this.accentColor,
  });

  static const _ink = Color(0xFF11155C);
  static const _muted = Color(0xFF7275B8);
  static const _lavender = Color(0xFFEEEEFA);

  @override
  Widget build(BuildContext context) {
    final subject = SubjectLabel.parse(evaluation.subjectName);
    final board = decodeExamBoard(
      SubjectLabel.payload(evaluation.subjectName, '@mesa='),
    ).where((member) => (member['name']?.toString().trim() ?? '').isNotEmpty);
    final date =
        DateFormat("EEEE d 'de' MMMM 'de' y", 'es_ES').format(evaluation.date);
    final accentTextColor =
        accentColor.computeLuminance() <= 0.183 ? Colors.white : Colors.black;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: _ink, fontSize: 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _muted.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton.filledTonal(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: _lavender,
                      foregroundColor: _ink,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border(
                      left: BorderSide(color: accentColor, width: 6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(evaluation.evaluationType,
                            style: TextStyle(
                                color: accentTextColor,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 8),
                      Text(subject.subjectName,
                          style: TextStyle(
                              color: accentColor,
                              fontSize: 25,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                          '${evaluation.careerName} · ${evaluation.semester}.º semestre',
                          style: const TextStyle(color: _muted)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: subjectColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Column(children: [
                    _detail(Icons.calendar_month_outlined,
                        '${date[0].toUpperCase()}${date.substring(1)}'),
                    const SizedBox(height: 12),
                    _detail(Icons.access_time_rounded,
                        _value(evaluation.time, 'Horario no asignado')),
                    const SizedBox(height: 12),
                    _detail(Icons.location_on_rounded,
                        _value(evaluation.classroom, 'Aula no asignada')),
                  ]),
                ),
                const SizedBox(height: 20),
                const Text('Mesa examinadora',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                if (board.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Mesa examinadora no asignada',
                        style: TextStyle(color: _muted)),
                  ),
                for (final member in board)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 23,
                        backgroundColor: _lavender,
                        child: Icon(
                            member['role'] == 'Presidente'
                                ? Icons.person
                                : Icons.person_outline,
                            color: accentColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member['name'].toString()),
                          Text(member['role']?.toString() ?? 'Miembro',
                              style: const TextStyle(color: _muted)),
                        ],
                      )),
                    ]),
                  ),
                const Divider(height: 28, color: Color(0xFFE0E1F6)),
                LayoutBuilder(builder: (context, constraints) {
                  final items = [
                    _metadata(Icons.groups_outlined, 'Grupo', 'No informado'),
                    _metadata(Icons.wb_sunny_outlined, 'Turno',
                        _value(subject.shift, 'No informado')),
                    _metadata(Icons.sell_outlined, 'Sección',
                        _value(subject.section, 'No informada')),
                  ];
                  return Wrap(
                    spacing: 12,
                    runSpacing: 16,
                    children: [
                      for (final item in items)
                        SizedBox(
                            width: constraints.maxWidth < 320
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 24) / 3,
                            child: item)
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _value(String? value, String fallback) =>
      value == null || value.trim().isEmpty ? fallback : value.trim();

  Widget _detail(IconData icon, String text) => Row(children: [
        Icon(icon, color: _ink, size: 25),
        const SizedBox(width: 16),
        Expanded(child: Text(text)),
      ]);

  Widget _metadata(IconData icon, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _ink, size: 23),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontSize: 13)),
            ],
          )),
        ],
      );
}
