import 'package:classify/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null); // Cambia 'es_ES' al idioma que desees

  // Se inicializa firebase
  await Firebase.initializeApp();
  runApp(const Classify());
}

class Classify extends StatelessWidget {
  const Classify({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}