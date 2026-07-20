import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queuecare_patient/features/appointments/appointments_screen.dart';
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
  group('AppointmentsScreen', () {
    testWidgets('renders appointments tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const AppointmentsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      // Wait for future builder
      await tester.pump(const Duration(seconds: 1));
      
      expect(find.text('À venir'), findsWidgets);
      expect(find.text('Historique'), findsWidgets);
    });
  });
}
