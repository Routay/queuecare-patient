import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestionnaire de stockage local universel (Web, Mobile, Desktop).
/// Utilise SharedPreferences au lieu de sqflite pour une compatibilité totale
/// sans aucune configuration native requise.
class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static const String _ticketKey = 'active_ticket';

  LocalDatabase._init();

  // --- Ticket Operations ---
  Future<void> saveActiveTicket(Map<String, dynamic> ticket) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ticketKey, jsonEncode(ticket));
  }

  Future<Map<String, dynamic>?> getActiveTicket() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_ticketKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> clearTicket() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ticketKey);
  }

  Future<void> close() async {
    // No-op: SharedPreferences doesn't need to be closed.
  }

  // --- Appointments Operations ---
  static const String _appointmentsKey = 'local_appointments';

  Future<void> saveAppointments(List<Map<String, dynamic>> appointments) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appointmentsKey, jsonEncode(appointments));
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_appointmentsKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> addAppointment(Map<String, dynamic> appointment) async {
    final appointments = await getAppointments();
    appointments.add(appointment);
    await saveAppointments(appointments);
  }

  // --- Notifications Operations ---
  static const String _notificationsKey = 'local_notifications';

  Future<void> saveNotifications(List<Map<String, dynamic>> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationsKey, jsonEncode(notifications));
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_notificationsKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> addNotification(Map<String, dynamic> notification) async {
    final notifications = await getNotifications();
    notifications.add(notification);
    await saveNotifications(notifications);
  }
}
