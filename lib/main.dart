import 'package:classlift/screens/home_screen.dart';
import 'package:classlift/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null); // Cambia 'es_ES' al idioma que desees

  // Se inicializa firebase
  await Firebase.initializeApp();

  final Database db = await DatabaseHelper.initializeDB();
  await DatabaseHelper.insertItem(db, 'Manzanas', 5);
  await DatabaseHelper.insertItem(db, 'Naranjas', 3);

  List<Map<String, dynamic>> items = await DatabaseHelper.getItems(db);
  print(items); // Muestra los elementos en la consola

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
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}