import 'package:flutter/material.dart';

class LoginTitle extends StatelessWidget {
  final Animation<double> animation;
  final double fontSize;

  const LoginTitle({
    super.key,
    required this.animation,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              const TextSpan(
                text: 'Class',
                children: [
                  TextSpan(
                      text: 'Lift', style: TextStyle(color: Color(0xFF3479F6))),
                ],
              ),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
                letterSpacing: -3.5,
                height: 1.1,
                color: const Color(0xFF0A173E),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'TU VIDA UNIVERSITARIA,\nEN ORDEN',
            style: TextStyle(
              color: Color(0xFF3F5181),
              fontSize: 11,
              letterSpacing: 3.2,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
