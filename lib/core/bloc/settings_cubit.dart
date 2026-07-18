import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final Locale locale;
  final ThemeMode themeMode;
  final bool isSimplifiedMode;

  const SettingsState({
    required this.locale,
    required this.themeMode,
    required this.isSimplifiedMode,
  });

  SettingsState copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    bool? isSimplifiedMode,
  }) {
    return SettingsState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      isSimplifiedMode: isSimplifiedMode ?? this.isSimplifiedMode,
    );
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit()
      : super(const SettingsState(
          locale: Locale('fr'),
          themeMode: ThemeMode.light,
          isSimplifiedMode: false,
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language') ?? 'fr';
    final theme = prefs.getString('theme') ?? 'light';
    final simplified = prefs.getBool('simplified') ?? false;

    emit(SettingsState(
      locale: Locale(lang),
      themeMode: theme == 'dark' ? ThemeMode.dark : ThemeMode.light,
      isSimplifiedMode: simplified,
    ));
  }

  Future<void> toggleLanguage() async {
    final newLocale = state.locale.languageCode == 'fr' 
        ? const Locale('wo') 
        : const Locale('fr');
    emit(state.copyWith(locale: newLocale));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', newLocale.languageCode);
  }

  Future<void> toggleTheme() async {
    final newTheme = state.themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    emit(state.copyWith(themeMode: newTheme));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', newTheme == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> toggleSimplifiedMode() async {
    final newValue = !state.isSimplifiedMode;
    emit(state.copyWith(isSimplifiedMode: newValue));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('simplified', newValue);
  }
}
