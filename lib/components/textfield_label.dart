import 'package:flutter/material.dart';

class TextfieldLabel extends StatelessWidget {
  const TextfieldLabel({super.key});

  Widget buildLabelAndTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool obscureText,
    required ValueNotifier<bool> obscureTextNotifier,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
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
              focusNode: focusNode,
              textInputAction: nextFocusNode != null
                  ? TextInputAction.next
                  : TextInputAction.done,
              onFieldSubmitted: (_) {
                if (nextFocusNode != null && nextFocusNode!.context != null) {
                  FocusScope.of(context).requestFocus(nextFocusNode);
                } else {
                  FocusScope.of(context).unfocus();
                }
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFF0F0F0),
                prefixIcon: Icon(icon, color: Color(0xFF66788A)),
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
                  vertical: 16.0,
                  horizontal: 16.0,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                  gapPadding: 0,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(
                    color: Color(0xFF4C9AFF),
                    width: 2.0,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(
                    color: Color(0xFFA41E25),
                    width: 2.0,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(
                    color: Color(0xFFA41E25),
                    width: 2.0,
                  ),
                ),
                hintText: hintText ?? 'Ingresá tu ${label.toLowerCase()}',
                hintStyle: TextStyle(
                  color: Color(0xFF66788A).withOpacity(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                isDense: true,
                errorStyle: TextStyle(
                  color: Color(0xFFA41E25),
                  fontSize: 14.0,
                  height: 1.4,
                ),
                helperText: null,
                helperStyle: TextStyle(
                  color: Color(0xFF66788A),
                  fontSize: 14.0,
                  fontWeight: FontWeight.w300,
                ),
                errorMaxLines: 2,
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
    return Container();
  }
}