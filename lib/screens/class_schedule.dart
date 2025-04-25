import 'package:flutter/material.dart';
import 'package:classlift/models/career.dart';
import 'package:classlift/utils/classlift_colors.dart';
import 'package:lottie/lottie.dart';

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

  bool isSemesterFullySelected(String career, int semester, List<String> subjects) {
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
    return selectedSubjectsByCareer.values.fold(0, (sum, set) => sum + set.length);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> sections = [];
    int careerIndex = 0;

    for (var careerEntry in widget.careerSemesters.entries) {
      final careerCode = careerEntry.key;
      final careerName = widget.careers.firstWhere(
            (c) => c.code == careerCode,
        orElse: () => Career(careerCode, careerCode),
      ).description;

      final semestersMap = careerEntry.value;
      final sortedSemesters = semestersMap.keys.toList()..sort();

      final careerBgColor = careerIndex++ % 2 == 0
          ? ClassliftColors.careerColorEven
          : ClassliftColors.careerColorOdd;

      int semesterIndex = 0;

      sections.add(
        Container(
          color: careerBgColor,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                careerName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              initiallyExpanded: expandedCareers[careerCode] ?? false,
              onExpansionChanged: (expanded) => setState(() => expandedCareers[careerCode] = expanded),
              trailing: AnimatedRotation(
                turns: (expandedCareers[careerCode] ?? false) ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.expand_more),
              ),
              children: sortedSemesters.map((semester) {
                final subjects = List<String>.from(semestersMap[semester]!);
                subjects.sort();
                final allSelected = isSemesterFullySelected(careerCode, semester, subjects);
                final semesterBgColor = semesterIndex++ % 2 == 0
                    ? ClassliftColors.semesterColorEven
                    : ClassliftColors.semesterColorOdd;

                return Container(
                  color: semesterBgColor,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text("Semestre $semester"),
                      initiallyExpanded: expandedSemesters[careerCode]?[semester] ?? false,
                      onExpansionChanged: (expanded) => setState(() => expandedSemesters[careerCode]![semester] = expanded),
                      trailing: AnimatedRotation(
                        turns: (expandedSemesters[careerCode]?[semester] ?? false) ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(Icons.expand_more),
                      ),
                      children: [
                        SubjectCheckboxTile(
                          title: 'Seleccionar todo el semestre',
                          isSelected: allSelected,
                          onTap: () => toggleSemester(careerCode, semester, subjects),
                          index: -1,
                          backgroundColor: ClassliftColors.selectAllColor,
                        ),
                        ...subjects.asMap().entries.map((entry) {
                          final subject = entry.value;
                          final index = entry.key;
                          final selected = isSubjectSelected(careerCode, subject);
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

    final isButtonEnabled = selectedSubjectsByCareer.values.any((set) => set.isNotEmpty);

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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
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
                padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 0.0),
                children: sections,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
              child: ElevatedButton(
                onPressed: isButtonEnabled
                    ? () {
                  final selectedMap = selectedSubjectsByCareer.map(
                        (key, value) => MapEntry(key, value.toList()),
                  );
                  Navigator.pop(context, selectedMap);
                }
                    : null,
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

class _SubjectCheckboxTileState extends State<SubjectCheckboxTile> with TickerProviderStateMixin {
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
        _controller.animateBack(0.0, duration: const Duration(milliseconds: 500));
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
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: widget.index % 2 == 0 ? Colors.white : const Color(0xFFF5F5F5),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: Lottie.asset(
                'assets/lottie/checkbox_lottie.json',
                controller: _controller,
                onLoaded: (composition) => _controller.duration = composition.duration,
              ),
            ),
          ],
        ),
      ),
    );
  }
}