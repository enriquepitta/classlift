import 'package:classlift/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:classlift/components/background_gradient.dart';
import 'controller/login_controller.dart';
import 'widgets/login_form.dart';
import 'widgets/register_form.dart';
import 'widgets/login_title.dart';
import 'widgets/bottom_section.dart';
import 'widgets/bottom_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
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
    final screenSize = MediaQuery.of(context).size;

    // Padding screen
    final horizontalPadding = ResponsiveUtils.padding(context, 'screen');

    // paddings valores personalizados
    final double topPadding;
    if (_controller.isRegisteringNotifier.value) {
      topPadding = ResponsiveUtils.getAdaptiveSize(context, small: 10.0, medium: 20.0, large: 0.0);
    } else {
      topPadding = ResponsiveUtils.getAdaptiveSize(context, small: 30.0, medium: 50.0, large: 0.0);
    }

    final spacing = screenSize.height * 0.025;

    return Scaffold(
      backgroundColor: Colors.blueAccent,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: _controller.dismissKeyboard,
        child: Stack(
          children: [
            const BackgroundGradient(),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: AnimatedPadding(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.only(top: 0.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Usa el estilo predefinido para títulos
                                LoginTitle(
                                  animation: _controller.titleAnimation,
                                  fontSize: ResponsiveUtils.fontStyle(context, 'title'),
                                ),
                                SizedBox(
                                  // Usa espaciado predefinido grande
                                  height: ResponsiveUtils.spacing(context, 'md'),
                                ),
                                ValueListenableBuilder<bool>(
                                  valueListenable: _controller.isRegisteringNotifier,
                                  builder: (context, isRegistering, _) {
                                    return AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 500),
                                      switchInCurve: Curves.easeInOut,
                                      switchOutCurve: Curves.easeInOut,
                                      transitionBuilder: (child, animation) {
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.0, 0.2),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: FadeTransition(opacity: animation, child: child),
                                        );
                                      },
                                      child: isRegistering
                                          ? RegisterForm(controller: _controller, spacing: spacing)
                                          : LoginForm(controller: _controller, spacing: spacing),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    BottomSection(controller: _controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(controller: _controller),
    );
  }
}