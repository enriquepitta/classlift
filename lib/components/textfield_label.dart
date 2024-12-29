import 'package:flutter/material.dart';

class TextfieldLabel extends StatelessWidget {
  const TextfieldLabel({super.key});

  Widget buildLabelAndTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool obscureText,
    required ValueNotifier<bool>
        obscureTextNotifier, // Para manejar el estado dinámico
    String? hintText, // HintText personalizado
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFFA3C1E2),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<bool>(
          valueListenable: obscureTextNotifier,
          builder: (context, isObscure, child) {
            return TextFormField(
              controller: controller,
              obscureText: isObscure,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFF0F0F0),
                // Color de fondo suave
                prefixIcon: Icon(icon, color: Color(0xFF66788A)),
                // Icono inicial
                suffixIcon: obscureText
                    ? IconButton(
                        icon: Icon(
                          isObscure ? Icons.visibility_off : Icons.visibility,
                          color: Color(0xFF66788A),
                        ),
                        onPressed: () {
                          obscureTextNotifier.value = !isObscure;
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18.0, // Incrementa el padding vertical
                  horizontal: 16.0,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none, // Sin borde, solo fondo
                  gapPadding: 0,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(
                    color: Color(0xFF4C9AFF), // Azul para el estado enfocado
                    width: 2.0,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(
                    color: Color(0xFFA41E25), // Borde moderno en rojo
                    width: 2.0,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(
                    color: Color(0xFFA41E25),
                    // Borde más oscuro para error enfocado
                    width: 2.0,
                  ),
                ),
                hintText: hintText ?? 'Ingresá tu ${label.toLowerCase()}',
                hintStyle: TextStyle(
                  color: Color(0xFF66788A).withOpacity(0.6),
                  // Color grisáceo para el hint
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                isDense: true,
                // Espaciado más compacto
                errorStyle: TextStyle(
                  color: Color(0xFFA41E25),
                  // Rojo para el texto del error (moderno y visible)
                  fontSize: 14.0,
                  // Tamaño compacto
                  height: 1.4, // Espaciado ajustado
                ),
                helperText: null,
                // Opcional: Puedes agregar un mensaje auxiliar elegante aquí
                helperStyle: TextStyle(
                  color: Color(0xFF66788A), // Color auxiliar suave
                  fontSize: 14.0,
                  fontWeight: FontWeight.w300,
                ),
                errorMaxLines: 2, // Permite texto más largo para errores
              ),
              validator: validator,
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // Este método se mantiene vacío para este widget.
  }
}
