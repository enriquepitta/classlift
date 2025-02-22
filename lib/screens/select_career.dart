import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:classlift/models/career.dart';
import 'package:classlift/utils/classlift_colors.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/scheduler.dart';

class SelectCareerScreen extends StatefulWidget {
  final List<String> availableSheets;
  final String? excelFilePath;

  SelectCareerScreen({required this.availableSheets, this.excelFilePath});

  @override
  _SelectCareerScreenState createState() => _SelectCareerScreenState();
}

class _SelectCareerScreenState extends State<SelectCareerScreen> with TickerProviderStateMixin {
  List<String> selectedCareerCodes = [];
  Map<int, List<String>> semesters = {};
  int maxSemester = 0;
  Map<int, bool> selectedSemesters = {};
  Map<String, bool> selectedSubjects = {};

  @override
  void initState() {
    super.initState();
  }

  void toggleSemester(int semester, bool? isChecked) {
    setState(() {
      selectedSemesters[semester] = isChecked ?? false;
      for (var subject in semesters[semester]!) {
        selectedSubjects[subject] = isChecked ?? false;
      }
    });
  }

  void toggleSubject(String subject, bool? isChecked) {
    setState(() {
      selectedSubjects[subject] = isChecked ?? false;

      for (var entry in semesters.entries) {
        if (entry.value.every((s) => selectedSubjects[s]!)) {
          selectedSemesters[entry.key] = true;
        } else {
          selectedSemesters[entry.key] = false;
        }
      }
    });
  }

  Future<int> getMaxSemester(String? filePath, String sheetName) async {
    if (filePath == null) return 0;
    var bytes = await File(filePath).readAsBytes();
    var excel = Excel.decodeBytes(bytes);

    int maxSemester = 0;

    if (excel.tables.containsKey(sheetName)) {
      var table = excel.tables[sheetName];

      for (var row in table!.rows) {
        if (row.length > 4) {
          String semesterValue = row[4]?.value.toString() ?? "0";
          int semester = int.tryParse(semesterValue) ?? 0;
          if (semester > maxSemester) {
            maxSemester = semester;
          }
        }
      }
    } else {
      print('La hoja $sheetName no existe en el archivo Excel.');
    }

    return maxSemester;
  }

  Future<void> processExcelFile(String? filePath, String sheetName) async {
    if (filePath == null) return;
    var bytes = await File(filePath).readAsBytes();
    var excel = Excel.decodeBytes(bytes);

    if (excel.tables.containsKey(sheetName)) {
      var table = excel.tables[sheetName];

      maxSemester = await getMaxSemester(filePath, sheetName);
      setState(() {
        for (int i = 1; i <= maxSemester; i++) {
          semesters[i] = [];
        }
      });

      for (var row in table!.rows) {
        if (row.length > 4) {
          String semesterValue = row[4]?.value.toString() ?? "0";
          int semester = int.tryParse(semesterValue) ?? 0;
          String subject = row[2]?.value.toString() ?? "";

          if (semester > 0 && subject.isNotEmpty) {
            setState(() {
              semesters[semester]?.add(subject);
              selectedSemesters[semester] = false;
              selectedSubjects[subject] = false;
            });
          }
        }
      }
    } else {
      print('La hoja $sheetName no existe en el archivo Excel.');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Career> filteredCareers = careers
        .where((career) => widget.availableSheets.contains(career.code))
        .toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0), // Ajusta la altura según necesites
        child: AppBar(
          title: const Text(
            "Seleccioná tu carrera",
            style: TextStyle(
              color: ClassliftColors.SecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: ClassliftColors.PrimaryColor,
          iconTheme: IconThemeData(
            color: ClassliftColors.SecondaryColor, // Cambia el color del botón de atrás
          ),
        ),
      ),
      body: Column(
        children: [
          // Muestra la cantidad de carreras seleccionadas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Text(
              'Seleccionaste ${selectedCareerCodes.length} carrera${selectedCareerCodes.length != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                child: CupertinoListSection(
                  backgroundColor: Colors.white,
                  children: filteredCareers.map((career) {
                    bool isSelected = selectedCareerCodes.contains(career.code);

                    return CareerCheckboxTile(
                      career: career,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedCareerCodes.remove(career.code);
                          } else {
                            selectedCareerCodes.add(career.code);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 0.0),
            child: ElevatedButton(
              onPressed: () {
                if (selectedCareerCodes.isNotEmpty) {
                  Navigator.pop(context, selectedCareerCodes);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Por favor, seleccione al menos una carrera')),
                  );
                }
              },
              child: const Text('Continuar'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: ClassliftColors.PrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class CareerCheckboxTile extends StatefulWidget {
  final Career career;
  final bool isSelected;
  final VoidCallback onTap;

  CareerCheckboxTile({
    required this.career,
    required this.isSelected,
    required this.onTap,
  });

  @override
  _CareerCheckboxTileState createState() => _CareerCheckboxTileState();
}

class _CareerCheckboxTileState extends State<CareerCheckboxTile> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(CareerCheckboxTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        // Reinicia la animación al principio y luego la reproduce en reversa
        _controller.value = 0.0; // Forzar el inicio desde el principio
        _controller.reverse();
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
    return CupertinoListTile(
      onTap: widget.onTap,
      backgroundColor: careers.indexOf(widget.career) % 2 == 0
          ? Colors.white // Color para índices pares
          : Colors.grey[200], // Color para índices impares
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          height: 60,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.career.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: Colors.black, // Cambia el color del texto a negro
              ),
            ),
          ),
        ),
      ),
      trailing: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Lottie.asset(
            'assets/lottie/checkbox_lottie.json',
            controller: _controller,
            onLoaded: (composition) {
              _controller.duration = composition.duration;
            },
          ),
        ),
      ),
    );
  }
}