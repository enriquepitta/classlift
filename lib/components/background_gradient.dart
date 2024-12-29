import 'package:flutter/material.dart';

class BackgroundGradient extends StatelessWidget {
  const BackgroundGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [
            // BK v2
            Color(0xFF333D86),
            Color(0xFF333D86),
            Color(0xFF4E7AB5),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),

            // BK v3
            // Color(0xFF333D86),
            // Color(0xFF4E7AB5),
            // Color(0xFFFFFFFF),
          ],
        ),
      ),
    );
  }
}


