import 'package:universal_html/html.dart' as html;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  NotificationService._internal();

  bool _hasPermission = false;

  /// Demande la permission d'afficher des notifications au navigateur
  Future<void> requestPermission() async {
    if (html.Notification.supported) {
      final permission = await html.Notification.requestPermission();
      _hasPermission = permission == 'granted';
    }
  }

  /// Affiche une notification système (fonctionne même si l'onglet est en arrière-plan)
  void showNotification(String title, String body) {
    if (html.Notification.supported && _hasPermission) {
      html.Notification(
        title,
        body: body,
        icon: 'icons/Icon-192.png', // Assuming PWA icon exists
      );
    }
  }
}
