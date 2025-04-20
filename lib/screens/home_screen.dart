import 'dart:io';
import 'package:classlift/screens/select_career.dart';
import 'package:classlift/widgets/NavigationMenu.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:classlift/utils/classlift_colors.dart';

import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedIndex = 0; // Índice para el BottomNavigationBar
  String? selectedCareerCode; // Definir la variable aquí
  String? _excelFilePath; // Añade esta variable para almacenar la ruta del archivo

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    Intl.defaultLocale = 'es_ES'; // Configura el idioma en español
  }

  void _toggleCalendarFormat() {
    setState(() {
      _calendarFormat = _calendarFormat == CalendarFormat.week
          ? CalendarFormat.month
          : CalendarFormat.week;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onFilePicked(String filePath) {
    // Aquí puedes manejar el archivo seleccionado
    print('Archivo seleccionado: $filePath');
    // Puedes agregar lógica adicional, como cargar el archivo en la aplicación
  }

  Future<void> pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        _excelFilePath = result.files.single.path; // Guarda la ruta del archivo
        var bytes = await File(_excelFilePath!).readAsBytes();
        var excel = Excel.decodeBytes(bytes);

        List<String> availableSheets = excel.tables.keys.toList();

        if (availableSheets.isNotEmpty) {
          if (!mounted) return; // Verifica si el widget sigue en el árbol
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SelectCareerScreen(
                availableSheets: availableSheets,
                excelFilePath: _excelFilePath,
              ),
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se encontraron hojas en el archivo Excel seleccionado')),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selección cancelada')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar el archivo: $e')),
      );
    }
  }

  void showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20),
                  SizedBox(height: 10),
                  Text(
                    'Seleccioná una opción',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.normal,
                      fontSize: 22,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),
                  ListTile(
                    leading: Icon(Icons.file_upload),
                    title: Text('Agregar horario de clases por Excel'),
                    onTap: () {
                      Navigator.pop(context);
                      pickExcelFile();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Agregar clases manualmente'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancelar'),
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
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Lottie.asset(
                  'assets/lottie/close.json',
                  height: 50,
                  width: 50,
                  repeat: false,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0), // Ajusta la altura según necesites
        child: AppBar(
          title: const Text(
            "Horario de Clases",
            style: TextStyle(
              color: ClassliftColors.SecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: ClassliftColors.PrimaryColor,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [ClassliftColors.White, ClassliftColors.BackgroundColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Calendario
            CalendarWidget(
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              calendarFormat: _calendarFormat,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
            ),
            // Footer interactivo
            CalendarFooter(
              calendarFormat: _calendarFormat,
              onTap: _toggleCalendarFormat,
            ),
            // Día seleccionado
            Expanded(
              child: Center(
                child: Text(
                  _selectedDay != null
                      ? 'Día seleccionado: ${DateFormat.yMMMMd('es_ES').format(_selectedDay!)}'
                      : 'Selecciona un día',
                  style: TextStyle(
                    fontSize: 16,
                    color: ClassliftColors.TextColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onFilePicked: _onFilePicked,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showOptionsBottomSheet(context);
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: ClassliftColors.SecondaryColor,
        shape: CircleBorder(), // Asegura que sea completamente redondo
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class CalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onPageChanged;

  CalendarWidget({
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: ClassliftColors.primaryGradient,
      ),
      child: TableCalendar(
        locale: 'es_ES',
        focusedDay: focusedDay,
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        calendarFormat: calendarFormat,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: onDaySelected,
        onFormatChanged: onFormatChanged,
        onPageChanged: onPageChanged,
        daysOfWeekHeight: 40,
        calendarStyle: CalendarStyle(
          weekendTextStyle: TextStyle(
            color: ClassliftColors.White,
            fontWeight: FontWeight.bold,
          ),
          defaultTextStyle: TextStyle(
            color: ClassliftColors.White,
            fontWeight: FontWeight.bold,
          ),
          todayTextStyle: TextStyle(
            color: ClassliftColors.SecondaryColor,
            fontWeight: FontWeight.bold,
          ),
          todayDecoration: BoxDecoration(),
          selectedDecoration: BoxDecoration(
            gradient: ClassliftColors.secondaryGradient,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            color: ClassliftColors.PrimaryColor,
            fontWeight: FontWeight.bold,
          ),
          outsideTextStyle: TextStyle(
            color: Colors.white54,
          ),
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextFormatter: (date, locale) {
            String formattedDate = DateFormat('MMMM', 'es_ES').format(date);
            return formattedDate[0].toUpperCase() + formattedDate.substring(1);
          },
          titleTextStyle: TextStyle(
            color: ClassliftColors.White,
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: ClassliftColors.White,
            size: 24,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: ClassliftColors.White,
            size: 24,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          dowTextFormatter: (date, locale) =>
              DateFormat.E(locale).format(date)[0].toUpperCase(),
          weekdayStyle: TextStyle(
            color: ClassliftColors.White,
            fontWeight: FontWeight.bold,
          ),
          weekendStyle: TextStyle(
            color: ClassliftColors.White,
            fontWeight: FontWeight.bold,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            final String dayText = DateFormat.E('es_ES').format(day)[0].toUpperCase();
            final bool isToday = isSameDay(day, DateTime.now());

            return Center(
              child: Text(
                dayText,
                style: TextStyle(
                  color: isToday ? ClassliftColors.SecondaryColor : ClassliftColors.White,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CalendarFooter extends StatelessWidget {
  final CalendarFormat calendarFormat;
  final VoidCallback onTap;

  CalendarFooter({
    required this.calendarFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: ClassliftColors.primaryGradient,
        ),
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Icon(
            calendarFormat == CalendarFormat.week
                ? Icons.expand_more
                : Icons.expand_less,
            color: ClassliftColors.White,
            size: 24,
          ),
        ),
      ),
    );
  }
}

// Funciones
void extractClassDetails(String subjectName, Sheet lciSheet) {
  print("🔍 Buscando detalles de clases para: $subjectName");

  // Recorremos las filas de la hoja Excel
  for (var row in lciSheet.rows) {
    // Comprobamos si la fila tiene suficientes columnas (en función de la cabecera)
    if (row.length > 10) {
      String item = row[0]?.value.toString() ?? ""; // Item
      String dpto = row[1]?.value.toString() ?? ""; // Departamento
      String subject = row[2]?.value.toString() ?? ""; // Asignatura
      String level = row[3]?.value.toString() ?? ""; // Nivel
      String semesterGroup = row[4]?.value.toString() ?? ""; // Semestre/Grupo
      String sigla = row[5]?.value.toString() ?? ""; // Sigla carrera
      String emphasis = row[6]?.value.toString() ?? ""; // Enfasis
      String plan = row[7]?.value.toString() ?? ""; // Plan
      String shift = row[8]?.value.toString() ?? ""; // Turno
      String section = row[9]?.value.toString() ?? ""; // Sección
      String platform = row[10]?.value.toString() ?? ""; // Plataforma aula virtual
      String title = row[11]?.value.toString() ?? ""; // Título
      String lastName = row[12]?.value.toString() ?? ""; // Apellido
      String firstName = row[13]?.value.toString() ?? ""; // Nombre
      String email = row[14]?.value.toString() ?? ""; // Correo Institucional
      String ExamenParcial1 = row[15]?.value.toString() ?? ""; // Día 1
      String HoraParcial1 = row[16]?.value.toString() ?? ""; // Hora 1
      String AulaParcial1 = row[17]?.value.toString() ?? ""; // Aula 1
      String ExamenParcial2 = row[18]?.value.toString() ?? ""; // Día 2
      String HoraParcial2 = row[19]?.value.toString() ?? ""; // Hora 2
      String AulaParcial2 = row[20]?.value.toString() ?? ""; // Aula 2
      String ExamenFinal1 = row[21]?.value.toString() ?? ""; // Día 3
      String HoraFinal1 = row[22]?.value.toString() ?? ""; // Hora 3
      String AulaFinal1 = row[23]?.value.toString() ?? ""; // Aula 3
      String ExamenFinal2 = row[26]?.value.toString() ?? ""; // Aula 4
      String HoraFinal2 = row[27]?.value.toString() ?? ""; // Día del examen
      String Lunes = row[35]?.value.toString() ?? ""; // Hora del examen
      String Martes = row[37]?.value.toString() ?? ""; // Aula del examen
      String Miercoles = row[39]?.value.toString() ?? ""; // Presidente
      String Jueves = row[41]?.value.toString() ?? ""; // Miembro 1
      String Viernes = row[43]?.value.toString() ?? ""; // Miembro 2
      String Sabado = row[45]?.value.toString() ?? ""; // Aula final

      if (subject == subjectName) {
        print("📚 Materia encontrada: $subject");

        // Muestra los detalles de la materia
        print("Departamento: $dpto");
        print("Nivel: $level");
        print("Semestre/Grupo: $semesterGroup");
        print("Sigla carrera: $sigla");
        print("Enfasis: $emphasis");
        print("Plan: $plan");
        print("Turno: $shift");
        print("Sección: $section");
        print("Plataforma: $platform");
        print("Título: $title");
        print("Docente: $lastName, $firstName");
        print("Correo: $email");

        // Muestra los días y horarios de clases
        print("Día 1: $ExamenParcial1, Hora 1: $HoraParcial1, Aula 1: $AulaParcial1");
        print("Día 2: $ExamenParcial2, Hora 2: $HoraParcial2, Aula 2: $AulaParcial2");
        print("Día 3: $ExamenFinal1, Hora 3: $HoraFinal1, Aula 3: $AulaFinal1");
        print("Día 4: $ExamenFinal2, Hora 4: $HoraFinal2, Aula 4: $ExamenFinal2");

        // Muestra los detalles del examen
        print("Examen: $HoraFinal2 $Lunes en Aula $Martes");

        // Muestra los miembros del jurado
        print("Presidentes: $Miercoles");
        print("Miembros: $Jueves, $Viernes");

        // Muestra la aula del final
        print("Aula final: $Sabado");

        return;
      }
    }
  }
  print("❌ No se encontró la asignatura '$subjectName'.");
}

void showSemesterSelection(BuildContext context, String selectedCareerCode) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Seleccione su semestre y materias',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Semestre 1'),
              onTap: () {
                Navigator.pop(context);
                // Mostrar selección de materias y turno para el semestre 1
                // Lógica adicional aquí, utilizando el selectedCareerCode si es necesario
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Semestre 2'),
              onTap: () {
                Navigator.pop(context);
                // Mostrar selección de materias y turno para el semestre 2
                // Lógica adicional aquí, utilizando el selectedCareerCode si es necesario
              },
            ),
            // Agregar más semestres si es necesario
          ],
        ),
      );
    },
  );
}
