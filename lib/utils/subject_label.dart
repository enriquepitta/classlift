// utils/subject_label.dart
//
// Las materias se guardan como un label concatenado con ' — ' que arma
// parseExcelForSheets:
//
//   materia — turno — sección? — profesor? — <horario> — @mesa=… — @eval=…
//
// Sección y profesor son opcionales, así que no se puede acceder por posición.
// Este parser centraliza la heurística que antes estaba duplicada en
// home_screen y database_service.
class SubjectLabel {
  final String subjectName;
  final String? shift;
  final String? section;
  final String? professor;

  const SubjectLabel({
    required this.subjectName,
    this.shift,
    this.section,
    this.professor,
  });

  static const _shifts = ['Mañana', 'Tarde', 'Noche'];

  factory SubjectLabel.parse(String label) {
    final parts = label.split(' — ');

    // Descarta el horario (contiene ':') y las cargas útiles codificadas
    // (@mesa=, @eval=), que de lo contrario se confundirían con el profesor.
    final metadata = parts
        .skip(1)
        .map((part) => part.trim())
        .where((part) =>
            part.isNotEmpty && !part.contains(':') && !part.startsWith('@'))
        .toList();

    final shift = metadata.firstWhere(
      _shifts.contains,
      orElse: () => '',
    );
    final section = metadata.firstWhere(
      (part) => RegExp(r'^[A-Z]{1,3}$').hasMatch(part),
      orElse: () => '',
    );
    final professor = metadata.firstWhere(
      (part) => part != shift && part != section,
      orElse: () => '',
    );

    return SubjectLabel(
      subjectName: parts.first.trim(),
      shift: shift.isEmpty ? null : shift,
      section: section.isEmpty ? null : section,
      professor: professor.isEmpty ? null : professor,
    );
  }

  /// Segmento codificado con el prefijo indicado (`@eval=`, `@mesa=`), o ''.
  static String payload(String label, String prefix) => label
      .split(' — ')
      .firstWhere((part) => part.startsWith(prefix), orElse: () => '');
}
