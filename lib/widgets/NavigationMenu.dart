import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:classlift/utils/classlift_colors.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final Function(String) onFilePicked; // Función para manejar el archivo seleccionado

  const CustomBottomNavigationBar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onFilePicked,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: ClassliftColors.PrimaryColor,
      shape: CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
      ),
    );
  }
}