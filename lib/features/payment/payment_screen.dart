import 'package:flutter/material.dart';
import 'package:queuecare_patient/core/theme/app_theme.dart';
import 'package:queuecare_patient/core/network/api_client.dart';
import 'package:queuecare_patient/core/database/local_database.dart';
import 'package:queuecare_patient/core/services/notification_service.dart';
import 'package:queuecare_patient/features/payment/payment_history_screen.dart';
import 'dart:ui' as ui;

class PaymentScreen extends StatefulWidget {
  final int amount;
  final String patientName;
  final String patientPhone;
  final String paymentType; // 'ticket' or 'appointment'

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.patientName,
    required this.patientPhone,
    required this.paymentType,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  String? _selectedOperator;
  Map<String, dynamic>? _receipt;

  Future<void> _processPayment(String operator) async {
    setState(() {
      _selectedOperator = operator;
      _isProcessing = true;
    });

    // Simulate payment gateway delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      final response = await ApiClient().dio.post('/payments/', data: {
        'patientName': widget.patientName.isEmpty ? 'Patient' : widget.patientName,
        'patientPhone': widget.patientPhone.isEmpty ? 'N/A' : widget.patientPhone,
        'type': widget.paymentType,
        'amount': widget.amount,
        'operator': operator,
      });

      final receipt = response.data['data'];

      // Save receipt as a notification
      final notif = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': 'Reçu de Paiement ($operator)',
        'body': 'Paiement de ${widget.amount} FCFA validé. ID: ${receipt['id']}',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': 'receipt',
        'data': receipt
      };
      await LocalDatabase.instance.addNotification(notif);

      NotificationService.instance.showNotification(
        "Paiement validé",
        "Votre reçu a été enregistré dans la messagerie."
      );

      setState(() {
        _isProcessing = false;
        _receipt = receipt;
      });

    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du paiement.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_receipt != null) {
      return _buildReceiptView(isDark);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.slateDark),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF0A0F1E)]
                : [const Color(0xFFF0FDFA), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sélectionnez un moyen de paiement',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Montant à payer : ${widget.amount} FCFA',
                  style: const TextStyle(fontSize: 18, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                
                if (_isProcessing)
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Connexion à l\'opérateur en cours...'),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      _buildOperatorCard('Wave', Colors.lightBlue, Icons.waves, isDark),
                      const SizedBox(height: 16),
                      _buildOperatorCard('Orange Money', Colors.deepOrange, Icons.monetization_on, isDark),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorCard(String name, Color color, IconData icon, bool isDark) {
    return GestureDetector(
      onTap: () => _processPayment(name),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.white54 : Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptView(bool isDark) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF0A0F1E)]
                : [AppTheme.primaryTeal, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 80),
              const SizedBox(height: 24),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Text('REÇU DE PAIEMENT', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const Divider(height: 40),
                      _receiptRow('ID', _receipt!['id'].toString().substring(0, 8)),
                      _receiptRow('Date', _receipt!['date'].toString().split('T')[0]),
                      _receiptRow('Opérateur', _receipt!['operator']),
                      _receiptRow('Montant', '${_receipt!['amount']} FCFA', isBold: true),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(context, true); // true = success
                          },
                          child: const Text('Continuer', style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentHistoryScreen(
                                patientPhone: widget.patientPhone.isEmpty ? 'N/A' : widget.patientPhone,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history, color: Colors.white70),
                        label: const Text('Voir l\'historique des paiements', style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
