import 'dart:convert';

class ParsedExcelEvaluation {
  final String type;
  final DateTime date;
  final String? time;
  final String? classroom;

  const ParsedExcelEvaluation({
    required this.type,
    required this.date,
    this.time,
    this.classroom,
  });

  Map<String, String> toMap() => {
        'type': type,
        'date': date.toIso8601String().substring(0, 10),
        if (time != null) 'time': time!,
        if (classroom != null) 'classroom': classroom!,
      };
}

class ParsedExamBoardMember {
  final String name;
  final String role;

  const ParsedExamBoardMember({required this.name, required this.role});

  Map<String, String> toMap() => {'name': name, 'role': role};
}

List<ParsedExcelEvaluation> parseExcelEvaluations(Map<int, String> row) {
  const definitions = [
    ('1.er Parcial', 15, 16, 17),
    ('2.do Parcial', 18, 19, 20),
    ('1.er Final', 21, 22, 23),
    ('Revisión', 24, 25, null),
    ('2.do Final', 26, 27, 28),
    ('Revisión final', 29, 30, null),
  ];

  final evaluations = <ParsedExcelEvaluation>[];
  for (final definition in definitions) {
    final date = parseExcelEvaluationDate(row[definition.$2]);
    if (date == null) continue;
    final time = normalizeExcelEvaluationTime(row[definition.$3]);
    final classroomIndex = definition.$4;
    final classroom =
        classroomIndex == null ? null : _nullableText(row[classroomIndex]);
    evaluations.add(ParsedExcelEvaluation(
      type: definition.$1,
      date: date,
      time: time,
      classroom: classroom,
    ));
  }
  return evaluations;
}

/// Lee la mesa examinadora desde los índices canónicos 31 (Presidente) y
/// 32/33 (Miembro). Las materias sin mesa asignada devuelven una lista vacía.
List<ParsedExamBoardMember> parseExamBoard(Map<int, String> row) {
  const definitions = [
    (31, 'Presidente'),
    (32, 'Miembro'),
    (33, 'Miembro'),
  ];

  final members = <ParsedExamBoardMember>[];
  for (final definition in definitions) {
    final name = _nullableText(row[definition.$1]);
    if (name == null) continue;
    members.add(ParsedExamBoardMember(name: name, role: definition.$2));
  }
  return members;
}

DateTime? parseExcelEvaluationDate(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;

  final numeric = double.tryParse(text.replaceAll(',', '.'));
  if (numeric != null && numeric >= 1 && numeric < 100000) {
    // Excel utiliza 1899-12-30 como base para sus fechas seriales.
    return DateTime(1899, 12, 30).add(Duration(days: numeric.floor()));
  }

  final dateMatch = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{2,4})').firstMatch(text);
  if (dateMatch != null) {
    final yearValue = int.parse(dateMatch.group(3)!);
    final year = yearValue < 100 ? 2000 + yearValue : yearValue;
    return DateTime(
      year,
      int.parse(dateMatch.group(2)!),
      int.parse(dateMatch.group(1)!),
    );
  }

  return DateTime.tryParse(text);
}

String? normalizeExcelEvaluationTime(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;

  final numeric = double.tryParse(text.replaceAll(',', '.'));
  if (numeric != null && numeric >= 0 && numeric < 1) {
    final minutes = (numeric * 24 * 60).round() % (24 * 60);
    return '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
        '${(minutes % 60).toString().padLeft(2, '0')}';
  }

  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(text);
  if (match == null) return null;
  return '${match.group(1)!.padLeft(2, '0')}:${match.group(2)!}';
}

String encodeExcelEvaluations(List<ParsedExcelEvaluation> evaluations) {
  final payload = evaluations.map((evaluation) => evaluation.toMap()).toList();
  return '@eval=${_encodePayload(payload)}';
}

List<Map<String, dynamic>> decodeExcelEvaluations(String value) =>
    _decodePayload(value, '@eval=');

String encodeExamBoard(List<ParsedExamBoardMember> members) {
  final payload = members.map((member) => member.toMap()).toList();
  return '@mesa=${_encodePayload(payload)}';
}

List<Map<String, dynamic>> decodeExamBoard(String value) =>
    _decodePayload(value, '@mesa=');

String _encodePayload(List<Map<String, String>> payload) =>
    base64UrlEncode(utf8.encode(jsonEncode(payload)));

List<Map<String, dynamic>> _decodePayload(String value, String prefix) {
  if (!value.startsWith(prefix)) return const [];
  try {
    final decoded =
        utf8.decode(base64Url.decode(value.substring(prefix.length)));
    final values = jsonDecode(decoded) as List<dynamic>;
    return values
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
  } on FormatException {
    return const [];
  }
}

String? _nullableText(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text;
}
