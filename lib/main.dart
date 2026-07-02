import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:queuecare_patient/core/localization/app_localizations.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/features/auth/auth_screen.dart';
import 'package:queuecare_patient/features/auth/onboarding_screen.dart';
import 'package:queuecare_patient/core/bloc/settings_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Vérification du premier lancement
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

  runApp(QueueCareApp(seenOnboarding: seenOnboarding));
}

class QueueCareApp extends StatelessWidget {
  final bool seenOnboarding;
  
  const QueueCareApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsCubit(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'QueueCare SN',
            debugShowCheckedModeBanner: false,
            
            // Gestion des thèmes via le Cubit
            theme: state.isSimplifiedMode ? AppTheme.simplifiedTheme : AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.themeMode,
            
            // Gestion des langues via le Cubit
            locale: state.locale,
            supportedLocales: const [
              Locale('fr', ''),
              Locale('wo', ''), // Wolof
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            
            // Constrain width on desktop web for a premium mobile-like feel
            builder: (context, child) {
              final isDark = state.themeMode == ThemeMode.dark || 
                (state.themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
              
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF020617) : const Color(0xFFE2E8F0),
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
                          blurRadius: 50,
                          spreadRadius: -10,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              );
            },
            
            home: seenOnboarding ? const AuthScreen() : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
