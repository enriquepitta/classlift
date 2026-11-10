import 'package:classlift/main.dart';
import 'package:classlift/router/app_router.dart';
import 'package:classlift/screens/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app router opens the social login screen', (tester) async {
    appRouter.go('/login');
    await tester.pumpWidget(const Classlift());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Continuar con Google').hitTestable(), findsOneWidget);
    expect(find.text('Continuar con Apple').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    appRouter.dispose();
  });
}
