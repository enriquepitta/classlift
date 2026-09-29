import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/utils/subject_label.dart';
import 'package:classlift/widgets/selection/selection_flow_widgets.dart';
import 'package:flutter/material.dart';

/// Groups only the presentation. Every option keeps its original storage label.
Map<String, List<String>> groupSubjectOptions(List<String> subjects) {
  final groups = <String, List<String>>{};
  for (final label in subjects) {
    final name = SubjectLabel.parse(label).subjectName;
    groups.putIfAbsent(name, () => []).add(label);
  }
  final names = groups.keys.toList()
    ..sort((a, b) => _sortText(a).compareTo(_sortText(b)));
  return {for (final name in names) name: groups[name]!};
}

String _sortText(String text) {
  var result = text.toLowerCase();
  const accents = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};
  accents
      .forEach((source, target) => result = result.replaceAll(source, target));
  return result;
}

class SubjectOptionsGroup extends StatelessWidget {
  final String subjectName;
  final List<String> options;
  final Set<String> selectedSubjects;
  final ValueChanged<String> onToggle;

  const SubjectOptionsGroup({
    super.key,
    required this.subjectName,
    required this.options,
    required this.selectedSubjects,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const shiftOrder = ['Mañana', 'Tarde', 'Noche'];
    final byShift = <String?, List<String>>{};
    for (final option in options) {
      final shift = SubjectLabel.parse(option).shift;
      byShift.putIfAbsent(shift, () => []).add(option);
    }
    int rank(String? shift) {
      final index = shiftOrder.indexOf(shift ?? '');
      return index < 0 ? shiftOrder.length : index;
    }

    final shifts = byShift.keys.toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));
    final selectedCount = options.where(selectedSubjects.contains).length;

    return SelectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectName,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: ClassliftColors.selectionInk,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${options.length} ${options.length == 1 ? 'opción disponible' : 'opciones disponibles'}'
                  '${selectedCount == 0 ? '' : ' · $selectedCount ${selectedCount == 1 ? 'elegida' : 'elegidas'}'}',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    fontWeight:
                        selectedCount > 0 ? FontWeight.w500 : FontWeight.w400,
                    color: selectedCount > 0
                        ? ClassliftColors.selectionBlue
                        : ClassliftColors.selectionMuted,
                  ),
                ),
              ],
            ),
          ),
          ...shifts.map((shift) {
            final shiftOptions = byShift[shift]!
              ..sort((a, b) {
                final aSection = SubjectLabel.parse(a).section;
                final bSection = SubjectLabel.parse(b).section;
                if (aSection == null && bSection != null) return 1;
                if (aSection != null && bSection == null) return -1;
                final sectionOrder = (aSection ?? '').compareTo(bSection ?? '');
                return sectionOrder == 0
                    ? _sortText(a).compareTo(_sortText(b))
                    : sectionOrder;
              });
            final icon = switch (shift) {
              'Mañana' => Icons.wb_sunny_outlined,
              'Tarde' => Icons.wb_twilight_rounded,
              'Noche' => Icons.nightlight_outlined,
              _ => Icons.schedule_rounded,
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 9),
                  child: Row(
                    children: [
                      Icon(icon,
                          size: 17, color: ClassliftColors.selectionBlue),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          shift ?? 'Turno sin especificar',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ClassliftColors.selectionBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Divider(
                          height: 1,
                          color: ClassliftColors.selectionBorder
                              .withValues(alpha: .45),
                        ),
                      ),
                    ],
                  ),
                ),
                ...shiftOptions.map((option) => Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: SubjectCheckboxTile(
                        key: ValueKey(option),
                        title: option,
                        isSelected: selectedSubjects.contains(option),
                        onTap: () => onToggle(option),
                      ),
                    )),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class SubjectCheckboxTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const SubjectCheckboxTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subject = SubjectLabel.parse(title);
    final section = subject.section == null
        ? 'Sección sin especificar'
        : 'Sección ${subject.section}';
    final schedule = title.split(' — ').firstWhere(
        (part) => part.contains(':') && !part.startsWith('@'),
        orElse: () => '');
    final times = <String>[];
    for (final entry in schedule.split(';')) {
      final separator = entry.indexOf(':');
      if (separator < 0) continue;
      final day = entry.substring(0, separator);
      final time = entry.substring(separator + 1).split('|').first;
      if (day.isNotEmpty && time.isNotEmpty) times.add('$day · $time');
    }

    return MergeSemantics(
      child: Semantics(
        checked: isSelected,
        label:
            '${subject.subjectName}, ${subject.shift ?? 'turno sin especificar'}',
        child: AnimatedContainer(
          duration: selectionAnimationDuration,
          curve: Curves.easeOutCubic,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isSelected
                ? ClassliftColors.selectionIcon
                : ClassliftColors.selectionSurface.withValues(alpha: .8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? ClassliftColors.selectionBorder
                  : ClassliftColors.selectionBorder.withValues(alpha: .22),
            ),
          ),
          child: Material(
            color: ClassliftColors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(section,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: ClassliftColors.selectionInk,
                              )),
                        ),
                        const SizedBox(width: 12),
                        SelectionIndicator(selected: isSelected),
                      ],
                    ),
                    if (subject.professor != null) ...[
                      const SizedBox(height: 8),
                      _OptionDetail(
                        icon: Icons.person_outline_rounded,
                        text: subject.professor!,
                      ),
                    ],
                    for (final time in times) ...[
                      const SizedBox(height: 6),
                      _OptionDetail(icon: Icons.schedule_rounded, text: time),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionDetail extends StatelessWidget {
  final IconData icon;
  final String text;

  const _OptionDetail({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: ClassliftColors.selectionMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                fontSize: 11,
                height: 1.4,
                color: ClassliftColors.selectionMuted,
              )),
        ),
      ],
    );
  }
}
