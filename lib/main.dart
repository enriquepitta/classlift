import 'package:classlift/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Importa Cupertino
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null); // Cambia 'es_ES' al idioma que desees

  // Se inicializa firebase
  await Firebase.initializeApp();

  runApp(const Classlift());
}

class Classlift extends StatelessWidget {
  const Classlift({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Poppins', // Aplica Poppins globalmente para Material
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Poppins'), // Asegura que Poppins se use en Material
        ),
      ),
      home: HomeScreen(),
      // Configura la fuente de Cupertino para usar Poppins
      builder: (context, child) {
        return CupertinoTheme(
          data: CupertinoThemeData(
            textTheme: CupertinoTextThemeData(
              textStyle: const TextStyle(fontFamily: 'Poppins'), // Aplica Poppins a Cupertino
            ),
          ),
          child: child!, // Pasa el child proporcionado por MaterialApp
        );
      },
    );
  }
}