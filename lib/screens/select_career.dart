import 'package:classlift/models/career.dart';
import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:excel/excel.dart';
import 'dart:io';

class SelectCareerScreen extends StatefulWidget {
  final List<String> availableSheets;
  final String? excelFilePath;

  SelectCareerScreen({required this.availableSheets, this.excelFilePath});

  @override
  _SelectCareerScreenState createState() => _SelectCareerScreenState();
}

class _SelectCareerScreenState extends State<SelectCareerScreen> {
  String? selectedCareerCode;
  Map<int, List<String>> semesters = {};
  int maxSemester = 0; // Variable para almacenar el número máximo de semestres
  Map<int, bool> selectedSemesters = {};
  Map<String, bool> selectedSubjects = {};

  @override
  void initState() {
    super.initState();
    // Inicializa selectedSemesters según el número máximo de semestres obtenido
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

      // Verificar si todas las materias del semestre están marcadas
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
          String semesterValue = row[4]?.value.toString() ?? "0"; // Suponiendo que la columna de semestre está en el índice 4
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

      // Obtener el número máximo de semestres
      maxSemester = await getMaxSemester(filePath, sheetName);
      setState(() {
        // Inicializar la estructura de datos para los semestres
        for (int i = 1; i <= maxSemester; i++) {
          semesters[i] = [];
        }
      });

      // Procesar las materias y asignarlas a los semestres
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
      appBar: AppBar(
        title: const Text(
          "Seleccionar Carrera",
          style: TextStyle(
            color: ClassliftColors.SecondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ClassliftColors.PrimaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0), // Añade padding alrededor de todo el contenido
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0), // Añade padding alrededor del selector de carrera
              child: DropdownSearch<String>(
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      labelText: "Buscar carrera",
                    ),
                  ),
                ),
                items: filteredCareers.map((c) => c.description).toList(),
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Carrera",
                    hintText: "Seleccione su carrera",
                    border: OutlineInputBorder(),
                  ),
                ),
                onChanged: (newValue) async {
                  var selectedCareer = filteredCareers.firstWhere((c) => c.description == newValue);
                  setState(() {
                    selectedCareerCode = selectedCareer.code;
                  });

                  // Procesar solo la hoja correspondiente a la carrera seleccionada
                  await processExcelFile(widget.excelFilePath, selectedCareerCode!);
                },
                selectedItem: selectedCareerCode != null
                    ? filteredCareers.firstWhere((c) => c.code == selectedCareerCode).description
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero, // Elimina cualquier padding interno
                children: semesters.keys.map((semester) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0.0), // Añade padding interno aquí
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero, // Elimina el padding interno de ExpansionTile
                      title: Row(
                        children: [
                          Checkbox(
                            value: selectedSemesters[semester],
                            onChanged: (isChecked) => toggleSemester(semester, isChecked),
                          ),
                          Text("Semestre $semester"),
                        ],
                      ),
                      children: semesters[semester]!.map((subject) {
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0), // Reduce padding
                          leading: Checkbox(
                            value: selectedSubjects[subject],
                            onChanged: (isChecked) => toggleSubject(subject, isChecked),
                          ),
                          title: Text(subject),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedCareerCode != null) {
                  Navigator.pop(context, selectedCareerCode);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Por favor, seleccione una carrera')),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
