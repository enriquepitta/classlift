import 'package:classlift/widgets/home/home_profile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Profile shows account and invokes sign out only when selected',
      (tester) async {
    var signOutCalls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: HomeProfileHeader(
        displayName: 'Ana Pérez',
        email: 'ana@example.com',
        subtitle: 'Tenés 3 clases por delante.',
        signingOut: false,
        onSignOut: () async {
          signOutCalls++;
        },
      )),
    ));
    expect(find.text('¡Hola, Ana!'), findsOneWidget);
    expect(find.text('Tenés 3 clases por delante.'), findsOneWidget);
    await tester.tap(find.byTooltip('Mi perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(signOutCalls, 0);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(signOutCalls, 1);
    expect(find.text('Mi cuenta'), findsNothing);
  });

  testWidgets('Missing name and sign out in progress are handled',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: HomeProfileHeader(
        subtitle: 'Todo listo para hoy ✨',
        signingOut: true,
        onSignOut: () async => fail('Sign out must not repeat'),
      )),
    ));
    expect(find.text('¡Hola!'), findsOneWidget);
    expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
  });
}
