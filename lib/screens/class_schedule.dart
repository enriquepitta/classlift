import 'package:classlift/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:classlift/models/career.dart';
import 'package:classlift/utils/classlift_colors.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import 'package:classlift/router/app_routes.dart';

class SelectSemesterScreen extends StatefulWidget {
  final Map<String, Map<int, List<String>>> careerSemesters;
  final List<String> selectedCareerCodes;
  final List<Career> careers;

  const SelectSemesterScreen({
    Key? key,
    required this.careerSemesters,
    required this.selectedCareerCodes,
    required this.careers,
  }) : super(key: key);

  @override
  _SelectSemesterScreenState createState() => _SelectSemesterScreenState();
}

class _SelectSemesterScreenState extends State<SelectSemesterScreen> {
  Map<String, Set<String>> selectedSubjectsByCareer = {};
  Map<String, bool> expandedCareers = {};
  Map<String, Map<int, bool>> expandedSemesters = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (var career in widget.selectedCareerCodes) {
      selectedSubjectsByCareer[career] = {};
      expandedCareers[career] = false;
      expandedSemesters[career] = {};

      final semesters = widget.careerSemesters[career]?.keys.toList() ?? [];
      for (var semester in semesters) {
        expandedSemesters[career]![semester] = false;
      }
    }
  }

  bool isSubjectSelected(String career, String subject) {
    return selectedSubjectsByCareer[career]?.contains(subject) ?? false;
  }

  bool isSemesterFullySelected(
      String career, int semester, List<String> subjects) {
    final selected = selectedSubjectsByCareer[career] ?? {};
    return subjects.every((s) => selected.contains(s));
  }

  void toggleSemester(String career, int semester, List<String> subjects) {
    final selected = selectedSubjectsByCareer[career] ?? {};
    final allSelected = isSemesterFullySelected(career, semester, subjects);
    setState(() {
      if (allSelected) {
        selected.removeAll(subjects);
      } else {
        selected.addAll(subjects);
      }
      selectedSubjectsByCareer[career] = selected;
    });
  }

  void toggleSubject(String career, String subject) {
    final selected = selectedSubjectsByCareer[career] ?? {};
    setState(() {
      if (selected.contains(subject)) {
        selected.remove(subject);
      } else {
        selected.add(subject);
      }
      selectedSubjectsByCareer[career] = selected;
    });
  }

  int getTotalSelectedSubjects() {
    return selectedSubjectsByCareer.values
        .fold(0, (sum, set) => sum + set.length);
  }

  // Función para manejar el guardado y navegación
  Future<void> _handleSaveAndNavigate([Route<dynamic>? summaryRoute]) async {
    if (!mounted || _isSaving) return;
    _isSaving = true;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    final selectionNavigator = Navigator.of(context);
    final loadingRoute = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Guardando materias...'),
            ],
          ),
        ),
      ),
    );
    void closeLoading() {
      if (navigator.mounted && loadingRoute.isActive) {
        navigator.removeRoute(loadingRoute);
      }
    }

    try {
      // Mostrar loading
      navigator.push(loadingRoute);

      print('Iniciando guardado de materias...'); // Debug

      // Guardar en la base de datos
      await DatabaseService.saveSelectedSubjects(
        selectedSubjectsByCareer
            .map((key, value) => MapEntry(key, value.toList())),
        widget.careers,
        widget.careerSemesters,
      );

      print('Materias guardadas exitosamente'); // Debug

      // Obtener estadísticas
      final totalCount = await DatabaseService.getTotalSubjectsCount();
      print('Total materias guardadas: $totalCount'); // Debug

      closeLoading();
      if (!mounted) return;
      final summaryNavigator = summaryRoute?.navigator;
      if (summaryRoute != null &&
          summaryNavigator != null &&
          summaryNavigator.mounted &&
          summaryRoute.isActive) {
        summaryNavigator.removeRoute(summaryRoute);
      }

      // Las referencias capturadas no dependen del State tras navegar.
      print('Navegando al home...'); // Debug
      // Carrera y materias se abren con Navigator.push, sin cambiar la URI.
      // Retirar esas rutas incluso si GoRouter ya se encuentra en /home.
      // Los overlays propios ya se cerraron arriba por su identidad exacta.
      if (selectionNavigator.mounted) {
        selectionNavigator.popUntil(
          (route) => route.settings is Page || route.isFirst,
        );
      }
      if (router.routeInformationProvider.value.uri.path != AppRoutes.home) {
        router.go(AppRoutes.home);
      }

      print('Navegación al home ejecutada'); // Debug

      // El ScaffoldMessenger conserva el aviso durante la navegación.
      if (messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Materias guardadas!',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$totalCount materia${totalCount != 1 ? 's' : ''} configurada${totalCount != 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('ERROR al guardar materias: $e'); // Debug

      // Cerrar loading si está abierto
      closeLoading();

      if (mounted && messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error al guardar: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () {
                if (mounted) _handleSaveAndNavigate(summaryRoute);
              },
            ),
          ),
        );
      }
    } finally {
      closeLoading();
      _isSaving = false;
    }
  }

  void _showSummaryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubjectSummaryBottomSheet(
        selectedSubjectsByCareer: selectedSubjectsByCareer,
        careers: widget.careers,
        careerSemesters: widget.careerSemesters,
        onSave: () => _handleSaveAndNavigate(ModalRoute.of(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> sections = [];
    int careerIndex = 0;

    for (var careerEntry in widget.careerSemesters.entries) {
      final careerCode = careerEntry.key;
      final careerName = widget.careers
          .firstWhere(
            (c) => c.code == careerCode,
            orElse: () => Career(careerCode, careerCode),
          )
          .description;

      final semestersMap = careerEntry.value;
      final sortedSemesters = semestersMap.keys.toList()..sort();

      final careerBgColor = careerIndex++ % 2 == 0
          ? ClassliftColors.careerColorEven
          : ClassliftColors.careerColorOdd;

      int semesterIndex = 0;

      sections.add(
        Material(
          color: careerBgColor,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                careerName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              initiallyExpanded: expandedCareers[careerCode] ?? false,
              onExpansionChanged: (expanded) =>
                  setState(() => expandedCareers[careerCode] = expanded),
              trailing: AnimatedRotation(
                turns: (expandedCareers[careerCode] ?? false) ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.expand_more),
              ),
              children: sortedSemesters.map((semester) {
                final subjects = List<String>.from(semestersMap[semester]!);
                subjects.sort();
                final allSelected =
                    isSemesterFullySelected(careerCode, semester, subjects);
                final semesterBgColor = semesterIndex++ % 2 == 0
                    ? ClassliftColors.semesterColorEven
                    : ClassliftColors.semesterColorOdd;

                return Material(
                  color: semesterBgColor,
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text("Semestre $semester"),
                      initiallyExpanded:
                          expandedSemesters[careerCode]?[semester] ?? false,
                      onExpansionChanged: (expanded) => setState(() =>
                          expandedSemesters[careerCode]![semester] = expanded),
                      trailing: AnimatedRotation(
                        turns:
                            (expandedSemesters[careerCode]?[semester] ?? false)
                                ? 0.5
                                : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(Icons.expand_more),
                      ),
                      children: [
                        SubjectCheckboxTile(
                          title: 'Seleccionar todo el semestre',
                          isSelected: allSelected,
                          onTap: () =>
                              toggleSemester(careerCode, semester, subjects),
                          index: -1,
                          backgroundColor: ClassliftColors.selectAllColor,
                        ),
                        ...subjects.asMap().entries.map((entry) {
                          final subject = entry.value;
                          final index = entry.key;
                          final selected =
                              isSubjectSelected(careerCode, subject);
                          final bgColor = index % 2 == 0
                              ? ClassliftColors.subjectColorEven
                              : ClassliftColors.subjectColorOdd;

                          return SubjectCheckboxTile(
                            title: subject,
                            isSelected: selected,
                            onTap: () => toggleSubject(careerCode, subject),
                            index: index,
                            backgroundColor: bgColor,
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    final isButtonEnabled =
        selectedSubjectsByCareer.values.any((set) => set.isNotEmpty);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          title: const Text(
            "Seleccioná materias",
            style: TextStyle(
              color: ClassliftColors.SecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: ClassliftColors.PrimaryColor,
          iconTheme: const IconThemeData(
            color: ClassliftColors.SecondaryColor,
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Seleccionaste ${getTotalSelectedSubjects()} materia${getTotalSelectedSubjects() != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 2.0, vertical: 0.0),
                children: sections,
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
              child: ElevatedButton(
                onPressed: isButtonEnabled ? _showSummaryBottomSheet : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: isButtonEnabled
                      ? ClassliftColors.PrimaryColor
                      : const Color(0xFFA3C1E2),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16.0),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubjectSummaryBottomSheet extends StatelessWidget {
  final Map<String, Set<String>> selectedSubjectsByCareer;
  final List<Career> careers;
  final Map<String, Map<int, List<String>>> careerSemesters;
  final VoidCallback onSave;

  const SubjectSummaryBottomSheet({
    Key? key,
    required this.selectedSubjectsByCareer,
    required this.careers,
    required this.careerSemesters,
    required this.onSave,
  }) : super(key: key);

  int getTotalSelectedSubjects() {
    return selectedSubjectsByCareer.values
        .fold(0, (sum, set) => sum + set.length);
  }

  Map<String, Map<int, List<String>>> _groupSubjectsBySemester() {
    Map<String, Map<int, List<String>>> groupedSubjects = {};

    for (var entry in selectedSubjectsByCareer.entries) {
      final careerCode = entry.key;
      final selectedSubjects = entry.value;

      if (selectedSubjects.isEmpty) continue;

      groupedSubjects[careerCode] = {};
      final careerSemesterMap = careerSemesters[careerCode] ?? {};

      // Para cada semestre, verificar qué materias están seleccionadas
      for (var semesterEntry in careerSemesterMap.entries) {
        final semester = semesterEntry.key;
        final allSubjectsInSemester = semesterEntry.value;

        final selectedInThisSemester = allSubjectsInSemester
            .where((subject) => selectedSubjects.contains(subject))
            .toList()
          ..sort();

        if (selectedInThisSemester.isNotEmpty) {
          groupedSubjects[careerCode]![semester] = selectedInThisSemester;
        }
      }
    }

    return groupedSubjects;
  }

  @override
  Widget build(BuildContext context) {
    final groupedSubjects = _groupSubjectsBySemester();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle del bottom sheet
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'Resumen de materias',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ClassliftColors.PrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${getTotalSelectedSubjects()} materia${getTotalSelectedSubjects() != 1 ? 's' : ''} seleccionada${getTotalSelectedSubjects() != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de materias agrupadas por carrera y semestre
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: groupedSubjects.entries.length,
                  itemBuilder: (context, careerIndex) {
                    final careerEntry =
                        groupedSubjects.entries.elementAt(careerIndex);
                    final careerCode = careerEntry.key;
                    final semesterMap = careerEntry.value;

                    if (semesterMap.isEmpty) return const SizedBox.shrink();

                    final careerName = careers
                        .firstWhere(
                          (c) => c.code == careerCode,
                          orElse: () => Career(careerCode, careerCode),
                        )
                        .description;

                    final totalSubjectsInCareer = semesterMap.values
                        .fold(0, (sum, list) => sum + list.length);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header de la carrera
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ClassliftColors.PrimaryColor,
                                  ClassliftColors.PrimaryColor.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.school,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    careerName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '$totalSubjectsInCareer materia${totalSubjectsInCareer != 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Semestres y materias
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children:
                                  semesterMap.entries.map((semesterEntry) {
                                final semester = semesterEntry.key;
                                final subjects = semesterEntry.value;
                                final isLastSemester =
                                    semesterEntry == semesterMap.entries.last;

                                return Container(
                                  margin: EdgeInsets.only(
                                      bottom: isLastSemester ? 0 : 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFE9ECEF)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header del semestre
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8F9FA),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                          border: Border(
                                            bottom: BorderSide(
                                                color: const Color(0xFFE9ECEF)),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color:
                                                    ClassliftColors.PrimaryColor
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.calendar_month,
                                                color: ClassliftColors
                                                    .PrimaryColor,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Semestre $semester',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color:
                                                    ClassliftColors.PrimaryColor
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${subjects.length}',
                                                style: TextStyle(
                                                  color: ClassliftColors
                                                      .PrimaryColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Lista de materias con detalles
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: subjects
                                              .asMap()
                                              .entries
                                              .map((subjectEntry) {
                                            final subjectIndex =
                                                subjectEntry.key;
                                            final subject = subjectEntry.value;
                                            final isLastSubject =
                                                subjectIndex ==
                                                    subjects.length - 1;

                                            // Parse subject details
                                            String cleanSubject = subject;
                                            String? shift;
                                            String? section;
                                            String? professor;
                                            String? schedule;

                                            if (subject.contains(' — ')) {
                                              final parts =
                                                  subject.split(' — ');
                                              if (parts.length >= 2) {
                                                cleanSubject = parts[0];
                                                shift = parts[1];
                                                if (parts.length >= 3) {
                                                  section = parts[2];
                                                }
                                                if (parts.length >= 4) {
                                                  professor = parts[3];
                                                }

                                                if (parts.length >= 5) {
                                                  schedule = parts[
                                                      4]; // Obtener el horario codificado
                                                }
                                              }
                                            }

                                            return Container(
                                              margin: EdgeInsets.only(
                                                  bottom:
                                                      isLastSubject ? 0 : 12),
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFAFAFA),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                    color:
                                                        const Color(0xFFE9ECEF)
                                                            .withOpacity(0.5)),
                                              ),
                                              // Dentro del Container donde muestras los detalles de la materia
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Nombre de la materia (código existente)
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4),
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.green,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.check,
                                                          color: Colors.white,
                                                          size: 12,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          cleanSubject,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.black87,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  // Detalles adicionales (código existente)
                                                  if (shift != null ||
                                                      section != null ||
                                                      professor != null ||
                                                      schedule != null) ...[
                                                    const SizedBox(height: 10),
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 6,
                                                      children: [
                                                        // ... código existente para shift y section ...
                                                      ],
                                                    ),

                                                    // Profesor (código existente)
                                                    if (professor != null) ...[
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .person_outline,
                                                            size: 14,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                          const SizedBox(
                                                              width: 6),
                                                          Expanded(
                                                            child: Text(
                                                              professor,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .grey[600],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],

                                                    // NUEVO: Horario de clases
                                                    _buildScheduleWidget(
                                                        schedule),
                                                  ],
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Botón de guardar
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: ClassliftColors.PrimaryColor,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.w600),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text('Guardar y Ver Horario'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SubjectCheckboxTile extends StatefulWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;
  final Color backgroundColor;

  const SubjectCheckboxTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.index,
    required this.backgroundColor,
    Key? key,
  }) : super(key: key);

  @override
  State<SubjectCheckboxTile> createState() => _SubjectCheckboxTileState();
}

class _SubjectCheckboxTileState extends State<SubjectCheckboxTile>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant SubjectCheckboxTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.animateBack(0.0,
            duration: const Duration(milliseconds: 500));
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
    // Separar título, turno, sección y profesor
    String cleanTitle = widget.title;
    String? shift;
    String? section;
    String? professor;

    if (widget.title.contains(' — ')) {
      final parts = widget.title.split(' — ');
      if (parts.length >= 2) {
        cleanTitle = parts[0];
        shift = parts[1];
        if (parts.length >= 3) {
          section = parts[2];
        }
        if (parts.length >= 4) {
          professor = parts[3];
        }
      }
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: widget.index % 2 == 0 ? Colors.white : const Color(0xFFF5F5F5),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cleanTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (shift != null ||
                      section != null ||
                      professor != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Turno
                        if (shift != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _getShiftColor(shift),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                shift,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        // Sección
                        if (section != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  _getSectionColor(section).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              section,
                              style: TextStyle(
                                fontSize: 10,
                                color: _getSectionColor(section),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        // Profesor
                        if (professor != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  professor,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 40,
              height: 40,
              child: Lottie.asset(
                'assets/lottie/checkbox_lottie.json',
                controller: _controller,
                onLoaded: (composition) =>
                    _controller.duration = composition.duration,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Agregar estas funciones en la clase SubjectSummaryBottomSheet
Color _getShiftColor(String? shift) {
  if (shift == null) return Colors.grey;
  switch (shift.toLowerCase()) {
    case 'mañana':
      return const Color(0xFF4CAF50); // Verde
    case 'tarde':
      return const Color(0xFFFF9800); // Naranja
    case 'noche':
      return const Color(0xFF3F51B5); // Azul oscuro
    default:
      return const Color(0xFF757575); // Gris
  }
}

IconData _getShiftIcon(String? shift) {
  if (shift == null) return Icons.access_time;
  switch (shift.toLowerCase()) {
    case 'mañana':
      return Icons.wb_sunny; // Sol
    case 'tarde':
      return Icons.wb_sunny_outlined; // Sol outline
    case 'noche':
      return Icons.nights_stay; // Luna
    default:
      return Icons.access_time; // Reloj
  }
}

Color _getSectionColor(String? section) {
  if (section == null) return Colors.grey;
  switch (section.toUpperCase()) {
    case 'NB':
      return const Color(0xFF9C27B0); // Púrpura
    case 'MI':
      return const Color(0xFF2196F3); // Azul
    case 'A':
      return const Color(0xFFE91E63); // Rosa
    case 'B':
      return const Color(0xFF00BCD4); // Cyan
    case 'C':
      return const Color(0xFFFF5722); // Naranja rojizo
    default:
      return const Color(0xFF607D8B); // Azul gris
  }
}

// Primero, asegúrate de tener la función para decodificar horarios
Map<String, String> _decodeSchedule(String encodedSchedule) {
  Map<String, String> schedule = {};
  if (encodedSchedule.isEmpty) return schedule;

  final entries = encodedSchedule.split(';');
  for (var entry in entries) {
    final parts = entry.split(':');
    if (parts.length >= 2) {
      final day = parts[0];
      final timeAndRoom = parts.sublist(1).join(':');
      schedule[day] = timeAndRoom;
    }
  }
  return schedule;
}

// Widget para mostrar el horario
Widget _buildScheduleWidget(String? encodedSchedule) {
  if (encodedSchedule == null || encodedSchedule.isEmpty) {
    return const SizedBox.shrink();
  }

  final schedule = _decodeSchedule(encodedSchedule);
  if (schedule.isEmpty) {
    return const SizedBox.shrink();
  }

  return Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: Colors.blue.withOpacity(0.2),
        width: 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 14,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 6),
            Text(
              'Horario',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...schedule.entries.map((entry) {
          final parts = entry.value.split('|');
          final time = parts.isNotEmpty ? parts[0] : '';
          final room = parts.length > 1 ? parts[1] : '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      if (time.isNotEmpty) ...[
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (room.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.room,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          room,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    ),
  );
}
