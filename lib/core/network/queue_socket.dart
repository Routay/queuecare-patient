import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Gère la connexion WebSocket au backend QueueCare avec reconnexion automatique.
/// Utilise un backoff exponentiel plafonné à 30s pour éviter de surcharger le serveur.
class QueueSocket {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  String? _currentTicketId;
  bool _shouldReconnect = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  static const int _maxReconnectAttempts = 8;
  static const String _wsBaseUrl =
      'wss://queuecare-backend-u770.onrender.com';

  /// Flux des messages JSON reçus du serveur.
  /// Inclut également des événements de statut : `{type: 'reconnecting'}`, `{type: 'connection_failed'}`.
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  bool get isConnected => _channel != null;

  // ──────────────────────────────────────────────────────────────────
  //  API publique
  // ──────────────────────────────────────────────────────────────────

  /// Établit la connexion avec le backend pour un ticket donné.
  void connect(String ticketId) {
    _currentTicketId = ticketId;
    _shouldReconnect = true;
    _reconnectAttempts = 0;
    _connectInternal();
  }

  /// Ferme proprement la connexion sans déclencher de reconnexion.
  void disconnect() {
    _shouldReconnect = false;
    _cleanup();
    debugPrint('🔌 [WS] Déconnecté volontairement.');
  }

  /// Libère toutes les ressources (appeler dans dispose() du widget).
  void dispose() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _cleanup();
    if (!_controller.isClosed) _controller.close();
    debugPrint('🗑️ [WS] QueueSocket libéré.');
  }

  // ──────────────────────────────────────────────────────────────────
  //  Logique interne
  // ──────────────────────────────────────────────────────────────────

  void _connectInternal() {
    _cleanup(); // Fermer l'éventuelle connexion précédente

    final wsUrl = Uri.parse('$_wsBaseUrl/queue/ws/$_currentTicketId');
    debugPrint('🔌 [WS] Connexion → $wsUrl');

    try {
      _channel = WebSocketChannel.connect(wsUrl);

      _subscription = _channel!.stream.listen(
        (event) {
          _reconnectAttempts = 0; // Succès : réinitialiser le compteur
          try {
            final data = jsonDecode(event as String) as Map<String, dynamic>;
            debugPrint('📥 [WS] $data');
            if (!_controller.isClosed) _controller.add(data);
          } catch (e) {
            debugPrint('⚠️ [WS] Erreur de parsing JSON : $e');
          }
        },
        onError: (error) {
          debugPrint('❌ [WS] Erreur : $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('🔌 [WS] Connexion fermée par le serveur.');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('❌ [WS] Impossible de se connecter : $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ [WS] Tentatives max atteintes. Abandon.');
      if (!_controller.isClosed) {
        _controller.add({'type': 'connection_failed'});
      }
      return;
    }

    _reconnectAttempts++;
    // Backoff exponentiel : 2s, 4s, 8s, 16s ... plafonné à 30s
    final delaySec = (2 * _reconnectAttempts).clamp(2, 30);
    debugPrint(
        '🔄 [WS] Reconnexion #$_reconnectAttempts dans ${delaySec}s...');

    if (!_controller.isClosed) {
      _controller.add({'type': 'reconnecting', 'attempt': _reconnectAttempts});
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySec), () {
      if (_shouldReconnect && _currentTicketId != null) {
        _connectInternal();
      }
    });
  }

  void _cleanup() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }
}
