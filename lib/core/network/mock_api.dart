import 'dart:async';
import 'dart:math';

class MockApi {
  // Simule l'authentification
  static Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    return username.isNotEmpty && password.isNotEmpty;
  }

  // Simule la récupération d'un ticket virtuel
  static Future<Map<String, dynamic>> fetchNewTicket(String department) async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'ticketNumber': 'A-${Random().nextInt(900) + 100}',
      'department': department,
      'position': Random().nextInt(20) + 5,
      'estimatedWaitTime': Random().nextInt(60) + 15,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Simule un flux WebSocket de l'avancement de la file d'attente
  static Stream<Map<String, dynamic>> queueStream(Map<String, dynamic> initialTicket) async* {
    int currentPosition = initialTicket['position'];
    int currentWaitTime = initialTicket['estimatedWaitTime'];

    yield {
      'position': currentPosition,
      'estimatedWaitTime': currentWaitTime,
      'updateType': 'init',
    };

    while (currentPosition > 0) {
      // Simule un patient qui passe toutes les 5 à 15 secondes
      await Future.delayed(Duration(seconds: Random().nextInt(10) + 5));
      currentPosition--;
      currentWaitTime = max(0, currentWaitTime - (Random().nextInt(5) + 2));
      
      yield {
        'position': currentPosition,
        'estimatedWaitTime': currentWaitTime,
        'updateType': 'progress',
      };
    }
  }

  // Simule la récupération de pharmacies
  static Future<List<Map<String, dynamic>>> fetchPharmacies() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      {
        'id': 1,
        'name': 'Pharmacie Guigon',
        'address': 'Avenue Georges Pompidou, Dakar',
        'latitude': 14.6672,
        'longitude': -17.4336,
      },
      {
        'id': 2,
        'name': 'Hôpital Principal de Dakar',
        'address': 'Avenue Nelson Mandela, Dakar',
        'latitude': 14.6631,
        'longitude': -17.4340,
      },
      {
        'id': 3,
        'name': 'Pharmacie de la Cathédrale',
        'address': 'Boulevard de la République, Dakar',
        'latitude': 14.6655,
        'longitude': -17.4360,
      },
    ];
  }
}
