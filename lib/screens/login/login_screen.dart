import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'controller/login_controller.dart';
import 'widgets/login_background.dart';
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
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final size = MediaQuery.sizeOf(context);
    final smallScreen = size.height < 740;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFEDF4FF),
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _controller.dismissKeyboard,
          child: Stack(
            children: [
              // Keep the artwork at full screen height while the keyboard opens.
              Positioned.fill(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: size.height,
                  child: SizedBox(
                    height: size.height,
                    child: const Stack(children: [LoginBackground()]),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        TweenAnimationBuilder<double>(
                                          tween: Tween<double>(
                                            end: keyboardVisible ? 0 : 1,
                                          ),
                                          duration:
                                              const Duration(milliseconds: 200),
                                          curve: Curves.easeOutCubic,
                                          builder: (context, expansion, _) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                SizedBox(
                                                    height: 12 +
                                                        (smallScreen ? 0 : 18) *
                                                            expansion),
                                                ClipRect(
                                                  child: Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    heightFactor: expansion,
                                                    child: Opacity(
                                                      opacity: expansion,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text(
                                                            'Organizá\ntu universidad,\nviví más.',
                                                            style: TextStyle(
                                                              color: Color(
                                                                  0xDDEAF3FF),
                                                              fontSize: 13,
                                                              height: 1.3,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 12),
                                                          const SizedBox(
                                                            width: 30,
                                                            child: Divider(
                                                              color: Color(
                                                                  0xB3FFFFFF),
                                                              thickness: 1.5,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              height:
                                                                  smallScreen
                                                                      ? 20
                                                                      : 44),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                LoginTitle(
                                                  animation: _controller
                                                      .titleAnimation,
                                                  fontSize: 44 + 18 * expansion,
                                                ),
                                                SizedBox(
                                                    height: 24 +
                                                        (smallScreen ? 0 : 12) *
                                                            expansion),
                                              ],
                                            );
                                          },
                                        ),
                                        ValueListenableBuilder<bool>(
                                          valueListenable:
                                              _controller.isRegisteringNotifier,
                                          builder: (context, isRegistering, _) {
                                            return AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 500),
                                              switchInCurve: Curves.easeInOut,
                                              switchOutCurve: Curves.easeInOut,
                                              transitionBuilder:
                                                  (child, animation) {
                                                return SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin:
                                                        const Offset(0.0, 0.2),
                                                    end: Offset.zero,
                                                  ).animate(animation),
                                                  child: FadeTransition(
                                                      opacity: animation,
                                                      child: child),
                                                );
                                              },
                                              child: isRegistering
                                                  ? RegisterForm(
                                                      controller: _controller,
                                                      spacing: 16)
                                                  : LoginForm(
                                                      controller: _controller,
                                                      spacing: 16),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          BottomSection(
                              controller: _controller,
                              keyboardVisible: keyboardVisible),
                          BottomNavigation(controller: _controller),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
