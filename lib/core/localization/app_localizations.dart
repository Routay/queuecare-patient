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
      // --- Queue Screen ---
      'realtime_tracking': 'Suivi en temps réel',
      'your_number': 'VOTRE NUMÉRO',
      'position_label': 'Position',
      'people_waiting': 'Personnes avant vous',
      'estimated_time': 'Temps estimé',
      'prepare_id': 'Préparez votre pièce d\'identité, c\'est bientôt votre tour !',
      'your_turn': 'C\'est votre tour !',
      'your_turn_subtitle': 'Veuillez vous diriger vers le bureau.',
      'no_active_ticket': 'Aucun ticket actif',
      'scan_qr_prompt': 'Scannez le QR Code à l\'hôpital\nou prenez un rendez-vous.',
      'scan_qr_button': 'Scanner un QR Code',
      'leave_queue': 'Quitter la file',
      'leave_queue_title': 'Quitter la file ?',
      'leave_queue_body': 'Êtes-vous sûr de vouloir annuler votre ticket ? Vous perdrez votre place.',
      'postpone': 'Reporter mon passage',
      'postpone_title': 'Reporter votre passage ?',
      'postpone_body': 'Vous serez déplacé à la dernière position de la file d\'attente. Souhaitez-vous continuer ?',
      'cancel_button': 'Annuler',
      'confirm_leave': 'Quitter',
      'confirm_postpone': 'Reporter',
      'postpone_success': 'Vous avez été déplacé à la fin de la file.',
      'postpone_error': 'Erreur lors du report. Veuillez réessayer.',
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
      // --- Queue Screen ---
      'realtime_tracking': 'Toppat ci saa si',
      'your_number': 'SA NIMERÓ',
      'position_label': 'Palaas',
      'people_waiting': 'Ñi ci sa kanam',
      'estimated_time': 'Waxtu bi ñu xar',
      'prepare_id': 'Teyaaral sa karti identité, gannaaw tuuti la !',
      'your_turn': 'Sa tour la !',
      'your_turn_subtitle': 'Jóg dem ci biro bi.',
      'no_active_ticket': 'Amoo ticket bu dox',
      'scan_qr_prompt': 'Scan-éel QR Code bi ci opital bi\nwalla jël rendez-vous.',
      'scan_qr_button': 'Scan-éel QR Code',
      'leave_queue': 'Génn ci rang bi',
      'leave_queue_title': 'Génn ci rang bi ?',
      'leave_queue_body': 'Ndax dëgg nga bëgg di génn ? Dinga ñàkk sa palaas.',
      'postpone': 'Yéggeelaat sama tuur',
      'postpone_title': 'Yéggeelaat sa tuur ?',
      'postpone_body': 'Dinga dem ci bitim rang bi. Ndax bëgg nga dem ?',
      'cancel_button': 'Neenal',
      'confirm_leave': 'Génn',
      'confirm_postpone': 'Yéggeelaat',
      'postpone_success': 'Dem nga ci bitim rang bi.',
      'postpone_error': 'Njuumte. Jéemaatal.',
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
