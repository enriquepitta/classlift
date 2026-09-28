import 'package:classlift/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:classlift/models/career.dart';
import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/utils/subject_label.dart';
import 'package:classlift/widgets/selection/selection_flow_widgets.dart';
import 'package:classlift/widgets/selection/subject_options_group.dart';
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
  State<SelectSemesterScreen> createState() => _SelectSemesterScreenState();
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
          backgroundColor: ClassliftColors.selectionSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          content: Row(
            children: [
              CircularProgressIndicator(color: ClassliftColors.selectionBlue),
              SizedBox(width: 20),
              Expanded(
                child: Text('Guardando materias...',
                    style: TextStyle(
                      color: ClassliftColors.selectionInk,
                      fontSize: 14,
                    )),
              ),
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
                    color: ClassliftColors.White, size: 20),
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
            backgroundColor: ClassliftColors.green,
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
                const Icon(Icons.error, color: ClassliftColors.White, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error al guardar: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: ClassliftColors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: ClassliftColors.White,
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
      backgroundColor: ClassliftColors.transparent,
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
    final total = getTotalSelectedSubjects();

    return SelectionFlowScaffold(
      title: 'Seleccioná',
      accentTitle: 'tus materias',
      description:
          'Elegí las materias que vas a cursar\ny armá tu horario a tu medida.',
      step: 2,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              widget.careerSemesters.entries.map((careerEntry) {
                final careerCode = careerEntry.key;
                final careerName = widget.careers
                    .firstWhere(
                      (career) => career.code == careerCode,
                      orElse: () => Career(careerCode, careerCode),
                    )
                    .description;
                final semesters = careerEntry.value.keys.toList()..sort();
                final selectedCount =
                    selectedSubjectsByCareer[careerCode]?.length ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SelectionSurface(
                    child: _SelectionExpansion(
                      title: careerName,
                      subtitle: selectedCount == 0
                          ? '${semesters.length} semestre${semesters.length == 1 ? ' disponible' : 's disponibles'}'
                          : '$selectedCount materia${selectedCount == 1 ? '' : 's'} seleccionada${selectedCount == 1 ? '' : 's'}',
                      leading: const SelectionIcon(),
                      expanded: expandedCareers[careerCode] ?? false,
                      onExpansionChanged: (expanded) => setState(
                          () => expandedCareers[careerCode] = expanded),
                      children: semesters.map((semester) {
                        final subjects =
                            List<String>.from(careerEntry.value[semester]!)
                              ..sort();
                        final subjectGroups = groupSubjectOptions(subjects);
                        final allSelected = isSemesterFullySelected(
                            careerCode, semester, subjects);
                        final selectedInSemester = subjects
                            .where((subject) =>
                                isSubjectSelected(careerCode, subject))
                            .length;

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: ClassliftColors.selectionSurface
                                  .withValues(alpha: .8),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: ClassliftColors.selectionBorder
                                      .withValues(alpha: .45)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _SelectionExpansion(
                              title: 'Semestre $semester',
                              subtitle: selectedInSemester == 0
                                  ? '${subjectGroups.length} materia${subjectGroups.length == 1 ? '' : 's'} · ${subjects.length} ${subjects.length == 1 ? 'opción' : 'opciones'}'
                                  : '$selectedInSemester de ${subjects.length} opciones seleccionadas',
                              leading: Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: ClassliftColors.selectionIcon,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Text('$semester',
                                    style: const TextStyle(
                                        color:
                                            ClassliftColors.PrimaryColorVariant,
                                        fontWeight: FontWeight.w600)),
                              ),
                              expanded: expandedSemesters[careerCode]
                                      ?[semester] ??
                                  false,
                              onExpansionChanged: (expanded) => setState(() =>
                                  expandedSemesters[careerCode]![semester] =
                                      expanded),
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                  child: Semantics(
                                    checked: allSelected,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => toggleSemester(
                                          careerCode, semester, subjects),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 14),
                                        child: Row(
                                          children: [
                                            const Expanded(
                                              child: Text(
                                                'Seleccionar todo el semestre',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: ClassliftColors
                                                      .PrimaryColorVariant,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            SelectionIndicator(
                                              selected: allSelected,
                                              partial: selectedInSemester > 0 &&
                                                  !allSelected,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                ...subjectGroups.entries.map((group) => Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          8, 0, 8, 12),
                                      child: SubjectOptionsGroup(
                                        key: ValueKey(
                                            '$careerCode/$semester/${group.key}'),
                                        subjectName: group.key,
                                        options: group.value,
                                        selectedSubjects:
                                            selectedSubjectsByCareer[
                                                    careerCode] ??
                                                {},
                                        onToggle: (subject) =>
                                            toggleSubject(careerCode, subject),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
      footer: SelectionFooter(
        caption: total == 0
            ? 'Elegí al menos una materia para continuar'
            : '$total materia${total == 1 ? '' : 's'} seleccionada${total == 1 ? '' : 's'}',
        onPressed: total > 0 ? _showSummaryBottomSheet : null,
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
    final total = getTotalSelectedSubjects();

    return DraggableScrollableSheet(
      initialChildSize: .7,
      minChildSize: .5,
      maxChildSize: .9,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  ClassliftColors.selectionIcon,
                  ClassliftColors.selectionSurface,
                  ClassliftColors.White,
                ],
              ),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    decoration: BoxDecoration(
                      color: ClassliftColors.selectionBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                    children: [
                      Row(
                        children: [
                          const SelectionIcon(icon: Icons.checklist_rounded),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Volver a la selección',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded,
                                color: ClassliftColors.selectionMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tu horario,\na un paso',
                        style: TextStyle(
                          fontSize: 28,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.6,
                          color: ClassliftColors.selectionInk,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        total == 1
                            ? 'Revisá la materia seleccionada antes de guardar.'
                            : 'Revisá tus $total materias antes de guardar.',
                        style: const TextStyle(
                            fontSize: 13,
                            color: ClassliftColors.selectionMuted),
                      ),
                      const SizedBox(height: 24),
                      ...groupedSubjects.entries.map((careerEntry) {
                        final careerName = careers
                            .firstWhere(
                              (career) => career.code == careerEntry.key,
                              orElse: () =>
                                  Career(careerEntry.key, careerEntry.key),
                            )
                            .description;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: SelectionSurface(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const SelectionIcon(),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(careerName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  ClassliftColors.selectionInk,
                                            )),
                                      ),
                                    ],
                                  ),
                                  ...careerEntry.value.entries.map((semester) =>
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 18, bottom: 12),
                                            child: SelectionBadge(
                                              label:
                                                  'Semestre ${semester.key} · ${semester.value.length} materia${semester.value.length == 1 ? '' : 's'}',
                                              icon: Icons.layers_outlined,
                                            ),
                                          ),
                                          ...semester.value.map((subject) =>
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 12),
                                                child: Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.all(14),
                                                  decoration: BoxDecoration(
                                                    color: ClassliftColors
                                                        .selectionSurface,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  child: _SubjectDetails(
                                                    label: subject,
                                                    showSchedule: true,
                                                  ),
                                                ),
                                              )),
                                        ],
                                      )),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                SelectionFooter(
                  label: 'Guardar y ver horario',
                  onPressed: onSave,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SelectionExpansion extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget leading;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final List<Widget> children;

  const _SelectionExpansion({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.expanded,
    required this.onExpansionChanged,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: expanded,
      onExpansionChanged: onExpansionChanged,
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      childrenPadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: leading,
      title: Text(title,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: ClassliftColors.selectionInk,
          )),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle,
            style: const TextStyle(
                fontSize: 11, color: ClassliftColors.selectionMuted)),
      ),
      trailing: AnimatedRotation(
        turns: expanded ? .5 : 0,
        duration: selectionAnimationDuration,
        curve: Curves.easeOutCubic,
        child: const Icon(Icons.keyboard_arrow_down_rounded,
            color: ClassliftColors.selectionMuted, size: 22),
      ),
      children: children,
    );
  }
}

/// Display-only parsing: the original complete label is still selected/saved.
class _SubjectDetails extends StatelessWidget {
  final String label;
  final bool showSchedule;

  const _SubjectDetails({required this.label, this.showSchedule = false});

  @override
  Widget build(BuildContext context) {
    final subject = SubjectLabel.parse(label);
    final schedule = label.split(' — ').firstWhere(
        (part) => part.contains(':') && !part.startsWith('@'),
        orElse: () => '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subject.subjectName,
            style: const TextStyle(
              color: ClassliftColors.selectionInk,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            )),
        if (subject.shift != null || subject.section != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (subject.shift != null)
                SelectionBadge(
                  label: subject.shift!,
                  icon: subject.shift == 'Noche'
                      ? Icons.nightlight_outlined
                      : Icons.wb_sunny_outlined,
                ),
              if (subject.section != null)
                SelectionBadge(label: 'Sección ${subject.section}'),
            ],
          ),
        ],
        if (subject.professor != null) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 15, color: ClassliftColors.selectionMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(subject.professor!,
                    style: const TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: ClassliftColors.selectionMuted)),
              ),
            ],
          ),
        ],
        if (showSchedule && schedule.isNotEmpty) _buildScheduleWidget(schedule),
      ],
    );
  }
}

// El horario conserva su codificación y sus valores originales.
Map<String, String> _decodeSchedule(String encodedSchedule) {
  final schedule = <String, String>{};
  if (encodedSchedule.isEmpty) return schedule;
  for (final entry in encodedSchedule.split(';')) {
    final parts = entry.split(':');
    if (parts.length >= 2) {
      schedule[parts[0]] = parts.sublist(1).join(':');
    }
  }
  return schedule;
}

Widget _buildScheduleWidget(String encodedSchedule) {
  final schedule = _decodeSchedule(encodedSchedule);
  if (schedule.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: schedule.entries.map((entry) {
        final parts = entry.value.split('|');
        final time = parts.first;
        final room = parts.length > 1 ? parts[1] : '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key,
                  style: const TextStyle(
                    color: ClassliftColors.PrimaryColorVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (time.isNotEmpty)
                    SelectionBadge(label: time, icon: Icons.schedule_rounded),
                  if (room.isNotEmpty)
                    SelectionBadge(
                        label: 'Aula $room', icon: Icons.location_on_outlined),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}
