import 'package:flutter/material.dart';
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
            
            home: seenOnboarding ? const AuthScreen() : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
