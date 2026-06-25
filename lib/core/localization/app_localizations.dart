import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'app_title': 'QueueCare SN',
      'welcome': 'Bienvenue sur QueueCare',
      'regular_patient': 'Patient Régulier',
      'occasional_patient': 'Patient Occasionnel',
      'login': 'Se Connecter',
      'continue_guest': 'Continuer sans compte',
      'home': 'Accueil',
      'queue': 'File d\'attente',
      'pharmacy': 'Pharmacie',
      'settings': 'Paramètres',
      'take_ticket': 'Prendre un ticket',
      'your_ticket': 'Votre Ticket',
      'estimated_wait': 'Temps d\'attente estimé',
      'minutes': 'min',
      'search_medicine': 'Rechercher un médicament...',
      'pharmacies_nearby': 'Pharmacies à proximité',
      'language': 'Langue',
      'theme': 'Thème',
      'simplified_mode': 'Mode Simplifié',
      'dark_mode': 'Mode Sombre',
      'logout': 'Se déconnecter',
      'current_number': 'Numéro Actuel',
      'your_position': 'Votre Position',
      'no_ticket': 'Vous n\'avez pas de ticket actif.',
    },
    'wo': {
      'app_title': 'QueueCare SN',
      'welcome': 'Dalal jamm ci QueueCare',
      'regular_patient': 'Kuy wër saafara saasë',
      'occasional_patient': 'Kuy wër saafara yenn say',
      'login': 'Dugu ci',
      'continue_guest': 'Dugu te amul compte',
      'home': 'Kër gi',
      'queue': 'Rang bi',
      'pharmacy': 'Saafara',
      'settings': 'Tann-Tann yi',
      'take_ticket': 'Jël ticket',
      'your_ticket': 'Sa Ticket',
      'estimated_wait': 'Xaar bi nu xar',
      'minutes': 'min',
      'search_medicine': 'Wër saafara...',
      'pharmacies_nearby': 'Fàrmasi yi ci sa wet',
      'language': 'Làmmiñ',
      'theme': 'Melo',
      'simplified_mode': 'Ndokkal',
      'dark_mode': 'Lëndëm',
      'logout': 'Génn',
      'current_number': 'Nimeró bifi nekk',
      'your_position': 'Sa Palaas',
      'no_ticket': 'Amo ticket legui.',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['fr']?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['fr', 'wo'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
