import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        ));

  void toggleLanguage() {
    final newLocale = state.locale.languageCode == 'fr' 
        ? const Locale('wo') 
        : const Locale('fr');
    emit(state.copyWith(locale: newLocale));
  }

  void toggleTheme() {
    final newTheme = state.themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    emit(state.copyWith(themeMode: newTheme));
  }

  void toggleSimplifiedMode() {
    emit(state.copyWith(isSimplifiedMode: !state.isSimplifiedMode));
  }
}
