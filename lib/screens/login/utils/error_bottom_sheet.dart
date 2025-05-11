import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void showErrorBottomSheet(BuildContext context, String errorMessage) {
  final Size screenSize = MediaQuery.of(context).size;
  final bool isSmallScreen = screenSize.width <= 375;

  final double initialChildSize = isSmallScreen ? 0.5 : 0.45;
  final double minChildSize = isSmallScreen ? 0.35 : 0.3;
  final double maxChildSize = isSmallScreen ? 0.7 : 0.6;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16.0 : 20.0,
                    vertical: isSmallScreen ? 25.0 : 30.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                margin: const EdgeInsets.only(bottom: 20),
                              ),
                              Lottie.asset(
                                'assets/lottie/Caution.json',
                                height: isSmallScreen ? 110 : 130,
                                repeat: false,
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 15),
                              Text(
                                'Atención',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: isSmallScreen ? 20 : 22,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 8 : 10),
                              Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[700],
                                  fontSize: isSmallScreen ? 15 : 17,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 15 : 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                            backgroundColor: const Color(0xFF333D86),
                            foregroundColor: Colors.white,
                            textStyle: TextStyle(
                              fontSize: isSmallScreen ? 15 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Entendí'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}