import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class QueueSocket {
  WebSocketChannel? _channel;
  
  /// Établit la connexion avec le backend FastAPI
  void connect(String ticketId) {
    // Fermer une ancienne connexion s'il y en a une
    disconnect();
    
    final wsUrl = Uri.parse('wss://queuecare-backend-u770.onrender.com/queue/ws/$ticketId');
    _channel = WebSocketChannel.connect(wsUrl);
    print('🔌 [WebSocket] Connecté au ticket $ticketId');
  }

  /// Flux (Stream) des messages JSON renvoyés par le serveur
  Stream<Map<String, dynamic>> get stream {
    if (_channel == null) {
      return const Stream.empty();
    }
    return _channel!.stream.map((event) {
      print('📥 [WebSocket Message] $event');
      return jsonDecode(event) as Map<String, dynamic>;
    });
  }

  /// Déconnexion propre
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      print('🔌 [WebSocket] Déconnecté');
    }
  }
}
