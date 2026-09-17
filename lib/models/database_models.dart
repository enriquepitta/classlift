// models/database_models.dart
class SelectedSubject {
  final int? id;
  final String careerCode;
  final String careerName;
  final int semester;
  final String subjectName;
  final String subjectCode; // Para futuras referencias
  final DateTime dateAdded;
  final DateTime? lastUpdated;
  final bool isActive;
  final String? notes; // Para notas del usuario
  final int? priority; // Para ordenamiento personalizado

  SelectedSubject({
    this.id,
    required this.careerCode,
    required this.careerName,
    required this.semester,
    required this.subjectName,
    required this.subjectCode,
    required this.dateAdded,
    this.lastUpdated,
    this.isActive = true,
    this.notes,
    this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'career_code': careerCode,
      'career_name': careerName,
      'semester': semester,
      'subject_name': subjectName,
      'subject_code': subjectCode,
      'date_added': dateAdded.millisecondsSinceEpoch,
      'last_updated': lastUpdated?.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'priority': priority,
    };
  }

  factory SelectedSubject.fromMap(Map<String, dynamic> map) {
    return SelectedSubject(
      id: map['id'],
      careerCode: map['career_code'],
      careerName: map['career_name'],
      semester: map['semester'],
      subjectName: map['subject_name'],
      subjectCode: map['subject_code'],
      dateAdded: DateTime.fromMillisecondsSinceEpoch(map['date_added']),
      lastUpdated: map['last_updated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_updated'])
          : null,
      isActive: map['is_active'] == 1,
      notes: map['notes'],
      priority: map['priority'],
    );
  }

  SelectedSubject copyWith({
    int? id,
    String? careerCode,
    String? careerName,
    int? semester,
    String? subjectName,
    String? subjectCode,
    DateTime? dateAdded,
    DateTime? lastUpdated,
    bool? isActive,
    String? notes,
    int? priority,
  }) {
    return SelectedSubject(
      id: id ?? this.id,
      careerCode: careerCode ?? this.careerCode,
      careerName: careerName ?? this.careerName,
      semester: semester ?? this.semester,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      dateAdded: dateAdded ?? this.dateAdded,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
    );
  }
}

// Modelo para futuras extensiones - Horarios
class SubjectSchedule {
  final int? id;
  final String subjectCode;
  final String careerCode;
  final String dayOfWeek; // 'monday', 'tuesday', etc.
  final String startTime; // '08:00'
  final String endTime; // '10:00'
  final String? classroom;
  final String? professor;
  final bool isActive;

  SubjectSchedule({
    this.id,
    required this.subjectCode,
    required this.careerCode,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.classroom,
    this.professor,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_code': subjectCode,
      'career_code': careerCode,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'classroom': classroom,
      'professor': professor,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory SubjectSchedule.fromMap(Map<String, dynamic> map) {
    return SubjectSchedule(
      id: map['id'],
      subjectCode: map['subject_code'],
      careerCode: map['career_code'],
      dayOfWeek: map['day_of_week'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      classroom: map['classroom'],
      professor: map['professor'],
      isActive: map['is_active'] == 1,
    );
  }
}

class ScheduledClass {
  final String subjectName;
  final String careerName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? classroom;
  final String? professor;

  const ScheduledClass({
    required this.subjectName,
    required this.careerName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.classroom,
    this.professor,
  });

  factory ScheduledClass.fromMap(Map<String, dynamic> map) {
    return ScheduledClass(
      subjectName: map['subject_name'] as String,
      careerName: map['career_name'] as String,
      dayOfWeek: map['day_of_week'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      classroom: map['classroom'] as String?,
      professor: map['professor'] as String?,
    );
  }
}

class SubjectEvaluation {
  final int? id;
  final String subjectCode;
  final String careerCode;
  final String evaluationType;
  final DateTime date;
  final String? time;
  final String? classroom;
  final String? professor;

  const SubjectEvaluation({
    this.id,
    required this.subjectCode,
    required this.careerCode,
    required this.evaluationType,
    required this.date,
    this.time,
    this.classroom,
    this.professor,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject_code': subjectCode,
        'career_code': careerCode,
        'evaluation_type': evaluationType,
        'evaluation_date': date.millisecondsSinceEpoch,
        'evaluation_time': time,
        'classroom': classroom,
        'professor': professor,
      };
}

class ExamBoardMember {
  final int? id;
  final String subjectCode;
  final String careerCode;
  final String role; // 'Presidente' o 'Miembro'
  final String name;
  final int position; // Preserva el orden de las columnas del Excel

  const ExamBoardMember({
    this.id,
    required this.subjectCode,
    required this.careerCode,
    required this.role,
    required this.name,
    required this.position,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject_code': subjectCode,
        'career_code': careerCode,
        'role': role,
        'member_name': name,
        'position': position,
      };

  factory ExamBoardMember.fromMap(Map<String, dynamic> map) {
    return ExamBoardMember(
      id: map['id'] as int?,
      subjectCode: map['subject_code'] as String,
      careerCode: map['career_code'] as String,
      role: map['role'] as String,
      name: map['member_name'] as String,
      position: map['position'] as int,
    );
  }
}

class UpcomingEvaluation {
  final String subjectName;
  final String subjectCode;
  final String careerCode;
  final String careerName;
  final int semester;
  final String evaluationType;
  final DateTime date;
  final String? time;
  final String? classroom;
  final String? professor;

  const UpcomingEvaluation({
    required this.subjectName,
    required this.subjectCode,
    required this.careerCode,
    required this.careerName,
    required this.semester,
    required this.evaluationType,
    required this.date,
    this.time,
    this.classroom,
    this.professor,
  });

  factory UpcomingEvaluation.fromMap(Map<String, dynamic> map) {
    return UpcomingEvaluation(
      subjectName: map['subject_name'] as String,
      subjectCode: map['subject_code'] as String,
      careerCode: map['career_code'] as String,
      careerName: map['career_name'] as String,
      semester: map['semester'] as int,
      evaluationType: map['evaluation_type'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['evaluation_date'] as int),
      time: map['evaluation_time'] as String?,
      classroom: map['classroom'] as String?,
      professor: map['professor'] as String?,
    );
  }
}

// Modelo para futuras extensiones - Notas/Calificaciones
class SubjectGrade {
  final int? id;
  final String subjectCode;
  final String careerCode;
  final String examType; // 'parcial1', 'parcial2', 'final', etc.
  final double? grade;
  final double maxGrade;
  final DateTime examDate;
  final String? notes;
  final bool isActive;

  SubjectGrade({
    this.id,
    required this.subjectCode,
    required this.careerCode,
    required this.examType,
    this.grade,
    required this.maxGrade,
    required this.examDate,
    this.notes,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_code': subjectCode,
      'career_code': careerCode,
      'exam_type': examType,
      'grade': grade,
      'max_grade': maxGrade,
      'exam_date': examDate.millisecondsSinceEpoch,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory SubjectGrade.fromMap(Map<String, dynamic> map) {
    return SubjectGrade(
      id: map['id'],
      subjectCode: map['subject_code'],
      careerCode: map['career_code'],
      examType: map['exam_type'],
      grade: map['grade']?.toDouble(),
      maxGrade: map['max_grade'].toDouble(),
      examDate: DateTime.fromMillisecondsSinceEpoch(map['exam_date']),
      notes: map['notes'],
      isActive: map['is_active'] == 1,
    );
  }
}
