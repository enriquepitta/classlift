import 'package:classlift/models/career.dart';
import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class SelectCareerScreen extends StatefulWidget {
  @override
  _SelectCareerScreenState createState() => _SelectCareerScreenState();
}

class _SelectCareerScreenState extends State<SelectCareerScreen> {
  String? selectedCareerCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0), // Ajusta la altura según necesites
        child: AppBar(
          title: const Text(
            "Seleccionar Carrera",
            style: TextStyle(
              color: ClassliftColors.SecondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: ClassliftColors.PrimaryColor,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownSearch<String>(
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          labelText: "Buscar carrera",
                        ),
                      ),
                    ),
                    items: careers.map((career) => career.description).toList(),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "Carrera",
                        hintText: "Seleccione su carrera",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    filterFn: (item, filter) => item.toLowerCase().contains(filter.toLowerCase()),
                    onChanged: (newValue) {
                      var selectedCareer = careers.firstWhere((career) => career.description == newValue);
                      setState(() {
                        selectedCareerCode = selectedCareer.code;
                      });
                    },
                    selectedItem: selectedCareerCode != null
                        ? careers.firstWhere((career) => career.code == selectedCareerCode).description
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 20), // Espacio para evitar que el botón quede pegado al borde
          ],
        ),
      ),
    );
  }
}
