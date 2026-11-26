import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/router/app_router.dart';
import 'package:classlift/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/account_service.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  binding.deferFirstFrame();
  runApp(const _Startup());
}

class _Startup extends StatefulWidget {
  const _Startup();
  @override
  State<_Startup> createState() => _StartupState();
}

class _StartupState extends State<_Startup> {
  late Future<void> _ready = _initialize();

  @override
  void initState() {
    super.initState();
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) async {
      try {
        // Keep the native splash visible until Flutter can paint the same icon.
        if (mounted) {
          await precacheImage(
              const AssetImage(SplashArtwork.logoAsset), context);
        }
      } finally {
        binding.allowFirstFrame();
      }
    });
  }

  Future<void> _initialize() async {
    await Firebase.initializeApp();
    await AccountService.instance.prepareCurrentAccount(migrateLegacy: true);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _ready,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError) {
            return const Classlift();
          }
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: snapshot.hasError
                  ? SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const Text(
                                'No pudimos abrir tus datos de forma segura.',
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () =>
                                  setState(() => _ready = _initialize()),
                              child: const Text('Reintentar'),
                            ),
                          ]),
                        ),
                      ),
                    )
                  : const SplashArtwork(),
            ),
          );
        },
      );
}

class Classlift extends StatelessWidget {
  const Classlift({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      title: 'ClassLift',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: ClassliftColors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      builder: (context, child) {
        return CupertinoTheme(
          data: const CupertinoThemeData(
            textTheme: CupertinoTextThemeData(
              textStyle: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          child: SplashScreen(child: child!),
        );
      },
    );
  }
}
