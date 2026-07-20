import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:queuecare_patient/features/queue/queue_screen.dart';
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
  group('QueueScreen', () {
    testWidgets('renders basic layout', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const QueueScreen()));
      await tester.pumpAndSettle();

      // Check if scanner button is present (fallback for empty state)
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
      
      // Since there's no ticket initially, it should show the "no ticket" state
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });
}
