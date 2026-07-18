import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:queuecare_patient/core/database/local_database.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  /// Initialise les notifications locales et le moteur TTS
  Future<void> requestPermission() async {
    if (_initialized) return;

    // --- Notifications locales Android ---
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initializationSettings: initSettings);

    // Demander la permission (Android 13+)
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // --- Moteur TTS (voix) ---
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.45); // Vitesse modérée, claire
    await _tts.setVolume(1.0); // Volume max
    await _tts.setPitch(1.05); // Tonalité légèrement élevée (alerte)

    _initialized = true;
    debugPrint('🔔 NotificationService initialisé (Notifications + TTS)');
  }

  /// Affiche une notification système ET annonce vocalement le message
  Future<void> showNotification(String title, String body,
      {bool speak = false}) async {
    
    if (!_initialized) {
      await requestPermission();
    }

    // --- Sauvegarde locale de la notification ---
    await LocalDatabase.instance.addNotification({
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // --- Notification visuelle ---
    const androidDetails = AndroidNotificationDetails(
      'queuecare_channel', // ID du canal
      'QueueCare Notifications', // Nom du canal
      channelDescription: 'Notifications de la file d\'attente QueueCare',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'QueueCare',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );

    // --- Annonce vocale (si demandée) ---
    if (speak) {
      await speakAnnouncement('$title. $body');
    }
  }

  /// Annonce vocale uniquement (Text-to-Speech)
  Future<void> speakAnnouncement(String message) async {
    try {
      await _tts.speak(message);
      debugPrint('🔊 TTS: $message');
    } catch (e) {
      debugPrint('❌ TTS Error: $e');
    }
  }

  /// Arrêter la synthèse vocale en cours
  Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}
