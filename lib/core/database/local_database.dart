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
}
