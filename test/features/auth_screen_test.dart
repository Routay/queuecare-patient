import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queuecare_patient/features/auth/auth_screen.dart';
import 'package:queuecare_patient/core/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget createTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('fr', ''),
      Locale('wo', ''),
    ],
    home: child,
  );
}

void main() {
  group('AuthScreen', () {
    testWidgets('renders phone and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const AuthScreen()));
      
      // Allow animations to finish
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Numéro de téléphone'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
    });

    testWidgets('renders login and guest buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const AuthScreen()));
      await tester.pumpAndSettle();

      // Find the Guest login text
      // Note: we can't search for exact loc strings easily without knowing the current locale,
      // but 'OU' is hardcoded in the UI
      expect(find.text('OU'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });

    testWidgets('obscures password by default and toggles visibility', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const AuthScreen()));
      await tester.pumpAndSettle();

      // Find password field by label
      final passwordField = find.ancestor(
        of: find.text('Mot de passe'),
        matching: find.byType(TextField),
      );
      
      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
    });
  });
}
