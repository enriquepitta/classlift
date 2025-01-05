import 'package:classify/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:classify/components/background_gradient.dart';
import 'package:classify/components/textfield_label.dart';
import 'package:classify/components/sign_button_row.dart';
import 'package:classify/screens/forgot_password_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'verification_email_screen.dart';

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

  bool _isRegistering = false;
  bool isLoading = false; // Variable para controlar el estado de carga

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
                                        if (!RegExp(
                                            r"^[a-zA-Z0-9._%+-]+@[a-zAolZ0-9.-]+\.[a-zA-Z]{2,4}$")
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
                                        keyboardType: TextInputType.emailAddress,
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
                              onPressed: () async {

                                // Navigator.of(context).pushReplacement(
                                //   MaterialPageRoute(builder: (context) => VerificationScreen()),
                                // );

                                // Validar el formulario según corresponda
                                if (_isRegistering
                                    ? _registerFormKey.currentState?.validate() ?? false
                                    : _loginFormKey.currentState?.validate() ?? false) {
                                  setState(() {
                                    isLoading = true; // Activa el spinner
                                  });

                                  try {
                                    if (_isRegistering) {
                                      // Registro
                                      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text.trim(),
                                      );

                                      // Si el registro fue exitoso, enviamos el correo de verificación
                                      await sendVerificationEmail(userCredential.user);

                                      print("Registro exitoso");

                                      // Redirigir a la pantalla de verificación o la pantalla que deseas mostrar
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => VerificationScreen()),
                                      );

                                    } else {
                                      // Inicio de sesión
                                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text.trim(),
                                      );

                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => HomeScreen()),
                                      );

                                      print("Inicio de sesión exitoso");
                                    }
                                  } // Uso en el manejo de FirebaseAuthException
                                  on FirebaseAuthException catch (e) {
                                    String errorMessage;
                                    if (e.code == 'email-already-in-use') {
                                      errorMessage = 'El correo ingresado ya está registrado. '
                                          'Inicia sesión o recupera tu contraseña desde "¿Olvidaste tu contraseña?".';
                                    } else if (e.code == 'weak-password') {
                                      errorMessage = 'La contraseña es muy débil. Usa letras, números y caracteres especiales con al menos 8 caracteres.';
                                    } else if (e.code == 'user-not-found') {
                                      errorMessage = 'No se encontró ninguna cuenta asociada a este correo. '
                                          'Verifica o regístrate si no tienes cuenta.';
                                    } else if (e.code == 'wrong-password') {
                                      errorMessage = 'La contraseña ingresada es incorrecta. '
                                          'Verifica o restablece tu contraseña desde "¿Olvidaste tu contraseña?".';
                                    } else {
                                      errorMessage = 'Ocurrió un error. Intenta más tarde o contacta al soporte: ${e.message}.';
                                    }

                                    // Llamar a la función para mostrar el BottomSheet
                                    showErrorBottomSheet(context, errorMessage);
                                  } finally {
                                    setState(() {
                                      isLoading = false; // Desactiva el spinner
                                    });
                                  }
                                }
                              },
                              child: isLoading
                                  ? Lottie.asset('assets/lottie/spinner_4.json',
                                  width: 35,
                                  height: 35,
                                  fit: BoxFit.contain,
                              ) // Usar el spinner de Lottie
                                  : Text(_isRegistering ? 'Regístrate' : 'Inicia sesión'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
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
                  ),
                  child: RichText(
                    text: TextSpan(
                      text: _isRegistering
                          ? '¿Ya tenés una cuenta? '
                          : '¿No tenés una cuenta? ',
                      style: TextStyle(
                        color: Color(0xFF333D86), // Color base
                        fontFamily: 'Poppins',
                        fontSize: 16, // Tamaño del texto base
                      ),
                      children: [
                        TextSpan(
                          text: _isRegistering ? 'Iniciá sesión' : 'Registrate',
                          style: const TextStyle(
                            fontWeight: FontWeight .w600, // Peso específico para estas palabras
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

Future<void> sendVerificationEmail(User? user) async {
  if (user != null && !user.emailVerified) {
    try {
      await user.sendEmailVerification();
      print("Correo de verificación enviado");
    } catch (e) {
      print("Error al enviar el correo de verificación: $e");
    }
  }
}


void showErrorBottomSheet(BuildContext context, String errorMessage) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return BottomSheet(
        onClosing: () {},
        builder: (context) {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Espaciado para el botón de cerrar (no visible aquí)
                    SizedBox(height: 20),

                    // Lottie animation for caution icon
                    Lottie.asset('assets/lottie/Caution.json', height: 200, width: 200),

                    SizedBox(height: 10),

                    // Título de error
                    Text(
                      'Atención',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Mensaje de error
                    Text(
                      errorMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 18,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Botón de OK
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Entendí'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: const Color(0xFFFF0000),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),

                  ],
                ),
              ),

              // Botón de cerrar
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(); // Cierra la pantalla/modal actual
                  },
                  child: Lottie.asset(
                    'assets/lottie/close.json',
                    height: 50,
                    width: 50,
                    repeat: false, // Solo animar una vez
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}