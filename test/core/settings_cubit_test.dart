import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:queuecare_patient/core/bloc/settings_cubit.dart';

void main() {
  group('SettingsCubit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state is correct (fr, light, not simplified)', () {
      final cubit = SettingsCubit();
      expect(cubit.state.locale, const Locale('fr'));
      expect(cubit.state.themeMode, ThemeMode.light);
      expect(cubit.state.isSimplifiedMode, false);
    });

    test('toggleLanguage changes fr to wo and updates SharedPreferences', () async {
      final cubit = SettingsCubit();
      await Future.delayed(Duration.zero); // Wait for loadSettings
      
      await cubit.toggleLanguage();
      
      expect(cubit.state.locale, const Locale('wo'));
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language'), 'wo');
    });

    test('toggleTheme changes light to dark and updates SharedPreferences', () async {
      final cubit = SettingsCubit();
      await Future.delayed(Duration.zero);
      
      await cubit.toggleTheme();
      
      expect(cubit.state.themeMode, ThemeMode.dark);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme'), 'dark');
    });

    test('toggleSimplifiedMode changes false to true and updates SharedPreferences', () async {
      final cubit = SettingsCubit();
      await Future.delayed(Duration.zero);
      
      await cubit.toggleSimplifiedMode();
      
      expect(cubit.state.isSimplifiedMode, true);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('simplified'), true);
    });

    test('loads saved settings on initialization', () async {
      SharedPreferences.setMockInitialValues({
        'language': 'wo',
        'theme': 'dark',
        'simplified': true,
      });

      final cubit = SettingsCubit();
      
      // Allow async init to complete
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(cubit.state.locale, const Locale('wo'));
      expect(cubit.state.themeMode, ThemeMode.dark);
      expect(cubit.state.isSimplifiedMode, true);
    });
  });
}
