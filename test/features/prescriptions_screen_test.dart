import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queuecare_patient/features/prescriptions/prescriptions_screen.dart';
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
    home: Scaffold(body: child),
  );
}

void main() {
  group('PrescriptionsScreen', () {
    testWidgets('renders prescriptions screen title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const PrescriptionsScreen()));
      await tester.pumpAndSettle();

      // Find the screen title
      expect(find.text('Mes Ordonnances'), findsWidgets);
      expect(find.byType(TabBar), findsOneWidget);
    });
  });
}
