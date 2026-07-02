import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/network/api_client.dart';
import 'package:queuecare_patient/core/database/local_database.dart';

class QRScannerUtils {
  static Future<void> showQRScannerDialog(
    BuildContext context, 
    {required Function(Map<String, dynamic>) onTicketScanned}
  ) async {
    // ANTI-SABOTAGE: Vérifier s'il y a déjà un ticket actif
    final activeTicket = await LocalDatabase.instance.getActiveTicket();
    
    if (activeTicket != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Anti-Sabotage : Vous avez déjà un ticket actif. Vous ne pouvez pas prendre plusieurs tickets simultanément.'
          ),
          backgroundColor: AppTheme.warning,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!context.mounted) return;

    String selectedDept = 'Consultation Générale';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulateur Scanner QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "En conditions réelles, cela ouvrirait l'appareil photo pour scanner le QR code de l'hôpital.",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedDept,
              decoration: const InputDecoration(
                labelText: 'Département ciblé par le QR',
                border: OutlineInputBorder(),
              ),
              items: ['Consultation Générale', 'Pédiatrie', 'Cardiologie', 'Pharmacie']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) selectedDept = val;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context); // Fermer le dialog
                  
                  try {
                    // Appel réel à l'API pour générer un ticket
                    final response = await ApiClient().dio.post(
                      '/queue/ticket',
                      data: {'department': selectedDept}
                    );
                    
                    if (context.mounted) {
                      // Save to local DB so it persists across app restarts!
                      await LocalDatabase.instance.saveActiveTicket(response.data);
                      
                      // Notifier l'appelant
                      onTicketScanned(response.data);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Code scanné ! Nouveau ticket généré pour $selectedDept.'),
                          backgroundColor: AppTheme.primaryTeal,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la génération du ticket : $e'),
                          backgroundColor: AppTheme.danger,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Simuler Scan QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
