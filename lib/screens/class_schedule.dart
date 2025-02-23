import 'package:classlift/models/career.dart';
import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'dart:io';

class SelectSemesterScreen extends StatefulWidget {
  final List<String> selectedCareerCodes;
  final List<String> availableSheets;
  final String? excelFilePath;

  const SelectSemesterScreen({
    Key? key,
    required this.selectedCareerCodes,
    required this.availableSheets,
    this.excelFilePath,
  }) : super(key: key);

  @override
  _SelectSemesterScreenState createState() => _SelectSemesterScreenState();
}

class _SelectSemesterScreenState extends State<SelectSemesterScreen> {
  int? selectedSemester;
  Map<int, List<String>> semesters = {};
  int maxSemester = 0;
  bool isLoading = true; // Estado de carga

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
    });

    if (widget.excelFilePath != null && widget.selectedCareerCodes.isNotEmpty) {
      await processExcelFile(widget.excelFilePath!, widget.selectedCareerCodes.first);
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> processExcelFile(String filePath, String sheetName) async {
    var bytes = await File(filePath).readAsBytes();
    var excel = Excel.decodeBytes(bytes);

    if (excel.tables.containsKey(sheetName)) {
      var table = excel.tables[sheetName];

      // Calcular el semestre máximo
      for (var row in table!.rows) {
        if (row.length > 4) {
          String semesterValue = row[4]?.value.toString() ?? "0";
          int semester = int.tryParse(semesterValue) ?? 0;
          if (semester > maxSemester) {
            maxSemester = semester;
          }
        }
      }

      // Llenar los semestres
      for (int i = 1; i <= maxSemester; i++) {
        semesters[i] = [];
      }

      for (var row in table.rows) {
        if (row.length > 4) {
          String semesterValue = row[4]?.value.toString() ?? "0";
          int semester = int.tryParse(semesterValue) ?? 0;
          String subject = row[2]?.value.toString() ?? "";

          if (semester > 0 && subject.isNotEmpty) {
            semesters[semester]?.add(subject);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Seleccionar Semestre",
          style: TextStyle(
            color: ClassliftColors.SecondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ClassliftColors.PrimaryColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Mostrar spinner mientras se carga
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: semesters.length,
                itemBuilder: (context, index) {
                  int semester = semesters.keys.elementAt(index);
                  return ExpansionTile(
                    title: Text("Semestre $semester"),
                    children: semesters[semester]!.map((subject) {
                      return ListTile(
                        title: Text(subject),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedSemester != null) {
                  Navigator.pop(context, selectedSemester);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Por favor, seleccione un semestre')),
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