import 'package:flutter/material.dart';
import 'package:classify/components/background_gradient.dart';
import 'package:classify/components/textfield_label.dart';
import 'package:classify/components/sign_google_button.dart';
import 'package:classify/components/sign_facebook_button.dart';
import 'package:classify/components/sign_button_row.dart';
import 'package:classify/screens/forgot_password_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();

  bool _isRegistering = false; // Controla si estamos en la pantalla de registro
  final ValueNotifier<bool> _passwordObscureNotifier =
  ValueNotifier<bool>(true);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleForm() {
    setState(() {
      _isRegistering = !_isRegistering;
    });
  }

  // Función para cerrar el teclado cuando se toca fuera del formulario
  void _dismissKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        // Cierra el teclado al tocar fuera del formulario
        onTap: _dismissKeyboard,
        child: Stack(
          children: [
            // Fondo con gradiente
            const BackgroundGradient(),

            // SafeArea para asegurar que el contenido no se vea afectado por el notch o la barra de navegación
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Parte superior con el título y el formulario
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Center(
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      colors: [
                                        Color(0xFF4E7AB5),
                                        Color(0xFFDCE4EF)
                                      ],
                                      // De oscuro a claro
                                      begin: Alignment.centerLeft,
                                      // Comienza desde la izquierda
                                      end: Alignment
                                          .centerRight, // Termina en la derecha
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    'PoliPlanner',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 52,
                                      color: Colors
                                          .white, // Necesitas un color base, se sobrepone el gradiente
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    0.03, // 3% de la altura de la pantalla
                              ),
                              Form(
                                key: _isRegistering
                                    ? _registerFormKey
                                    : _loginFormKey,
                                child: Column(
                                  children: [
                                    if (_isRegistering) ...[
                                      // Campo de texto para el nombre
                                      TextfieldLabel().buildLabelAndTextField(
                                        label: 'Nombre completo',
                                        controller: _nameController,
                                        icon: Icons.person,
                                        obscureText: false,
                                        obscureTextNotifier:
                                        ValueNotifier<bool>(false),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Por favor ingresá tu nombre';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(
                                        height: MediaQuery.of(context)
                                            .size
                                            .height *
                                            0.03, // 3% de la altura de la pantalla
                                      ),
                                    ],
                                    // Campo de texto para el correo electrónico
                                    TextfieldLabel().buildLabelAndTextField(
                                      label: 'Correo electrónico',
                                      controller: _emailController,
                                      icon: Icons.email,
                                      obscureText: false,
                                      obscureTextNotifier:
                                      ValueNotifier<bool>(false),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor ingresa un correo electrónico';
                                        }
                                        if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$")
                                            .hasMatch(value)) {
                                          return 'Por favor ingresa un correo electrónico válido';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(
                                      height: MediaQuery.of(context)
                                          .size
                                          .height *
                                          0.03, // 3% de la altura de la pantalla
                                    ),

                                    // Campo de texto para la contraseña
                                    TextfieldLabel().buildLabelAndTextField(
                                      label: 'Contraseña',
                                      controller: _passwordController,
                                      icon: Icons.lock,
                                      obscureText: true,
                                      obscureTextNotifier:
                                      _passwordObscureNotifier,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor ingresa una contraseña';
                                        }
                                        return null;
                                      },
                                    ),

                                    if (!_isRegistering) ...[
                                      // Botón para "¿Olvidaste tu contraseña?"
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                const ForgotPasswordPage(),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            '¿Olvidaste tu contraseña?',
                                            style: TextStyle(
                                              color: Color(0xFF333D86),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],

                                    if (_isRegistering) ...[
                                      SizedBox(
                                        height: MediaQuery.of(context)
                                            .size
                                            .height *
                                            0.03, // 3% de la altura de la pantalla
                                      ),
                                      // Campo para confirmar la contraseña
                                      TextfieldLabel().buildLabelAndTextField(
                                        label: 'Confirmar contraseña',
                                        controller: _confirmPasswordController,
                                        icon: Icons.lock,
                                        obscureText: true,
                                        obscureTextNotifier:
                                        _passwordObscureNotifier,
                                        keyboardType:
                                        TextInputType.emailAddress,
                                        hintText: 'Confirmá tu contraseña',
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Por favor confirma tu contraseña';
                                          }
                                          if (value !=
                                              _passwordController.text) {
                                            return 'Las contraseñas no coinciden';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.03, // 3% de la altura de la pantalla
                    ),

                    // Parte inferior con los botones
                    Column(
                      children: [
                        AnimatedPadding(
                          padding: EdgeInsets.only(top: 0),
                          duration: Duration(
                              milliseconds: 300), // Duración de la animación
                          curve: Curves
                              .easeInOut, // Tipo de curva para la animación
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF4E7AB5),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFA3C1E2).withOpacity(0.5),
                                  offset: Offset(0, 3),
                                  blurRadius: 5,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (_isRegistering
                                    ? _registerFormKey.currentState
                                    ?.validate() ??
                                    false
                                    : _loginFormKey.currentState?.validate() ??
                                    false) {
                                  // Procesar los datos del login o registro
                                  print(_isRegistering
                                      ? "Registro exitoso"
                                      : "Iniciar sesión");
                                }
                              },
                              child: Text(_isRegistering
                                  ? 'Registrate'
                                  : 'Iniciá sesión'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                textStyle: TextStyle(fontSize: 16.0),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.03, // 3% de la altura de la pantalla
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        // padding: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFF4E7AB5),
            ],
          ),

          // color: Colors.red,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFF333D86),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        margin: const EdgeInsets.only(right: 10),
                      ),
                    ),
                    Text(
                      "O continuá con",
                      style: const TextStyle(
                        color: Color(0xFF333D86),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF333D86),
                              Colors.transparent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        margin: const EdgeInsets.only(left: 10),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.03, // 3% de la altura de la pantalla
                ),

                SignInButtonsRow(
                  onGooglePressed: () {
                    print("Google");
                  },
                  onFacebookPressed: () {
                    print("Facebook");
                  },
                  onApplePressed: () {
                    print("Apple");
                  },
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.01, // 3% de la altura de la pantalla
                ),
                // Botón de alternancia entre registro e inicio de sesión
                TextButton(
                  onPressed: _toggleForm,
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF333D86),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  child: RichText(
                    text: TextSpan(
                      text: _isRegistering
                          ? '¿Ya tenés una cuenta? '
                          : '¿No tenés una cuenta? ',
                      style: TextStyle(
                        color: Color(0xFF333D86), // Color base
                        fontSize: 16, // Tamaño del texto base
                      ),
                      children: [
                        TextSpan(
                          text: _isRegistering ? 'Iniciá sesión' : 'Registrate',
                          style: TextStyle(
                            fontWeight: FontWeight
                                .bold, // Peso específico para estas palabras
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
