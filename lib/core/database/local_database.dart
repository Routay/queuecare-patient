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

  // --- User Profile Operations ---
  static const String _profileKey = 'user_profile';

  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile));
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_profileKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return {'name': '', 'phone': ''};
  }

  Future<void> clearUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }

  // --- Authentication Operations ---
  static const String _usersKey = 'registered_users';
  static const String _sessionKey = 'current_session_phone';

  Future<void> registerUser(String name, String phone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final String usersJson = prefs.getString(_usersKey) ?? '{}';
    Map<String, dynamic> users = jsonDecode(usersJson);

    if (users.containsKey(phone)) {
      throw Exception('Ce numéro de téléphone est déjà utilisé.');
    }

    users[phone] = {
      'name': name,
      'phone': phone,
      'password': password,
    };

    await prefs.setString(_usersKey, jsonEncode(users));
    
    // Automatically log in and save profile
    await prefs.setString(_sessionKey, phone);
    await saveUserProfile({'name': name, 'phone': phone});
  }

  Future<bool> loginUser(String phone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final String usersJson = prefs.getString(_usersKey) ?? '{}';
    Map<String, dynamic> users = jsonDecode(usersJson);

    if (users.containsKey(phone)) {
      final user = users[phone];
      if (user['password'] == password) {
        await prefs.setString(_sessionKey, phone);
        await saveUserProfile({'name': user['name'], 'phone': user['phone']});
        return true;
      }
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove('is_guest_session');
    await clearUserProfile();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_sessionKey);
  }

  Future<void> setGuestSession(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest_session', isGuest);
  }

  Future<bool> isGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_guest_session') ?? false;
  }
}
