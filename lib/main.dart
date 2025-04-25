import 'package:classlift/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  await Firebase.initializeApp();

  runApp(const Classlift());
}

class Classlift extends StatelessWidget {
  const Classlift({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      home: SplashScreen(),
      builder: (context, child) {
        return CupertinoTheme(
          data: CupertinoThemeData(
            textTheme: CupertinoTextThemeData(
              textStyle: const TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}