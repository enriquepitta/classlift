import 'package:classlift/screens/class_schedule.dart';
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
  bool isLoading = false; // Estado de carga

  @override
  void initState() {
    super.initState();
  }

  Future<void> _processExcelFile() async {
    if (widget.excelFilePath == null || selectedCareerCodes.isEmpty) return;

    setState(() {
      isLoading = true; // Activar el estado de carga
    });

    // Simula el procesamiento del archivo Excel (cambia esto por tu lógica real)
    await Future.delayed(Duration(seconds: 2)); // Simulación de carga

    setState(() {
      isLoading = false; // Desactivar el estado de carga
    });

    // Navegar a la siguiente pantalla
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectSemesterScreen(
          availableSheets: widget.availableSheets,
          excelFilePath: widget.excelFilePath,
          selectedCareerCodes: selectedCareerCodes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Career> filteredCareers = careers
        .where((career) => widget.availableSheets.contains(career.code))
        .toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
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
            color: ClassliftColors.SecondaryColor,
          ),
        ),
      ),
      body: Container(
        color: Color(0xFFF5F5F5),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
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
              child: ListView.builder(
                itemCount: filteredCareers.length,
                itemBuilder: (context, index) {
                  final career = filteredCareers[index];
                  final isSelected = selectedCareerCodes.contains(career.code);

                  return CareerCheckboxTile(
                    index: index,
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
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: ClassliftColors.PrimaryColor,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                    if (selectedCareerCodes.isNotEmpty) {
                      _processExcelFile();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor, seleccione al menos una carrera')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      if (!isLoading)
                        const Text('Continuar'),
                    ],
                  ),
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

class CareerCheckboxTile extends StatefulWidget {
  final int index;
  final Career career;
  final bool isSelected;
  final VoidCallback onTap;

  CareerCheckboxTile({
    required this.index,
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
          : Color(0xFFF5F5F5), // Color para índices impares
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