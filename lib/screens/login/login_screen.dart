import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'controller/login_controller.dart';
import 'widgets/login_background.dart';
import 'widgets/login_title.dart';
import 'widgets/bottom_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController(context, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 740;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFEDF4FF),
        body: Stack(
          children: [
            const LoginBackground(),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: LayoutBuilder(builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 32),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    LoginTitle(
                                      animation: _controller.titleAnimation,
                                      fontSize: compact ? 52 : 62,
                                    ),
                                    SizedBox(height: compact ? 20 : 28),
                                    const Text(
                                      'Organizá tus clases, horarios y tareas\nen un solo lugar.',
                                      style: TextStyle(
                                        color: Color(0xFF526797),
                                        fontSize: 15,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: compact ? 32 : 56),
                              BottomNavigation(controller: _controller),
                              const SizedBox(height: 20),
                              const Text(
                                'Si es tu primera vez, creamos tu cuenta\ncon la opción que elijas.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Color(0xFF526797),
                                    fontSize: 12,
                                    height: 1.6),
                              ),
                              SizedBox(height: compact ? 24 : 40),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
